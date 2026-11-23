"""Run cross-encoding, CLI and independent-reader checks on the synthetic corpus."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unicodedata
import pyreadstat

from capture import capture
from compare_oracle import compare
from pspp_oracle import binary, compare as compare_pspp
from raw_dictionary_oracle import audit

ROOT = Path(__file__).resolve().parents[1]


def readstat_cp1258(source, bundle, rows, metadata):
    """Verify parser output with Latin-1 as a reversible byte transport.

    Some iconv implementations buffer CP1258 characters while looking for
    combining marks. ReadStat's converter does not flush at the end of a
    field. A reversible transport keeps the binary format comparison
    independent of that decoder.
    """
    frame, reference = pyreadstat.read_sav(
        str(source), encoding="ISO-8859-1", user_missing=True,
        disable_datetime_conversion=True, output_format="dict",
    )

    def decode(text):
        return text.encode("latin1").decode("cp1258")

    assert reference.column_names == ["ID", "SCORE", "NOTE"]
    assert reference.number_rows == len(rows) == 3
    for index, (name, values) in enumerate(frame.items()):
        variable = metadata["variables"][index]
        assert variable["name"] == name
        assert variable["type"] == ("numeric" if name == "SCORE" else "string")
        if name == "SCORE":
            assert reference.missing_ranges[name] == [{"lo": 99., "hi": 99.}]
            assert [None if value is None else float(value) for value in values] == [88., 99., None]
        else:
            assert [decode(value) for value in values] == [row[index]["text"].rstrip(" ") for row in rows]
        label = reference.column_names_to_labels[name]
        assert (None if label is None else decode(label)) == variable["label"]
        labels = reference.variable_value_labels.get(name, {})
        assert {key: decode(label) for key, label in labels.items()} == {
            float(label["value"]["decimal"]): label["label"] for label in variable["value_labels"]
        }
    assert not audit(source.read_bytes(), metadata)
    _, default = pyreadstat.read_sav(str(source), metadataonly=True, user_missing=True)
    if default.column_names != reference.column_names:
        return {
            "status": "oracle_disagreement",
            "classification": "readstat_default_cp1258_names_disagree",
            "expected_variable_names": reference.column_names,
            "actual_variable_names": default.column_names,
            "independent_byte_transport": "supported_pass",
            "transport_encoding": "ISO-8859-1",
            "decoder": "CPython strict cp1258",
            "oracle": "ReadStat via pyreadstat " + pyreadstat.__version__,
        }
    result = compare(source, bundle)
    result["independent_byte_transport"] = "supported_pass"
    return result


def classify_pspp(result, expected, csv_path):
    """Record the observed CP1258 normalization without awarding an exact pass."""
    if result["status"] == "supported_pass":
        return
    expected_differences = [{"field": "value", "variable_index": 2, "row": i} for i in range(3)]
    if result["exit_code"] != 0 or result["differences"] != expected_differences:
        return
    with csv_path.open(encoding="utf-8", newline="") as file:
        notes = [row["note"] for row in csv.DictReader(file)]
    composed = unicodedata.normalize("NFC", expected)
    if composed != expected and notes == [composed] * 3:
        result["classification"] = "oracle_normalizes_cp1258_to_nfc"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    out = parser.parse_args().output.resolve()
    out.mkdir(parents=True)
    fixtures = ROOT / "fixtures/synthetic/windows-codepages"
    manifest = json.loads((fixtures / "manifest.json").read_text())
    results = []
    for fixture in manifest:
        source = fixtures / fixture["file"]
        assert hashlib.sha256(source.read_bytes()).hexdigest() == fixture["sha256"]
        report = out / source.stem
        bundle = out / "payloads" / source.stem
        bundle.parent.mkdir(exist_ok=True)
        code, _, _ = capture(["node", "bin/moonsav.mjs", "export", str(source),
                              "--out", str(bundle), "--json"], report, inputs=[source])
        if code:
            raise RuntimeError(f"MoonSav export failed for {source.name} with exit {code}")
        code, _, _ = capture(["node", "bin/moonsav.mjs", "check-bundle", str(bundle), "--json"], report)
        if code:
            raise RuntimeError(f"MoonSav bundle check failed for {source.name} with exit {code}")
        metadata = json.loads((bundle / "metadata.json").read_text())
        assert metadata["encoding"]["effective"] == fixture["profile"]
        expected = fixture["expected_text"]
        assert metadata["variables"][1]["label"] == expected
        assert metadata["variables"][1]["value_labels"][0]["label"] == expected
        rows = [json.loads(line)["cells"] for line in (bundle / "data.ndjson").read_text().splitlines()]
        assert [(r[0]["text"].rstrip(" "), r[1]["decimal"], r[1]["missing"], r[2]["text"]) for r in rows] == [
            ("0012", "88", "present", expected), ("NA", "99", "user", expected), ("\\N", None, "system", expected)
        ]
        is_cp1258 = fixture["profile"] == "windows-1258"
        pspp_result = compare_pspp(source, bundle, report / "pspp",
                                   reference_encoding="ISO-8859-1" if is_cp1258 else None)
        if is_cp1258:
            classify_pspp(pspp_result, expected, report / "pspp/payloads/oracle.csv")
        readstat = readstat_cp1258(source, bundle, rows, metadata) if is_cp1258 else compare(source, bundle)
        results.append({
            "file": source.name,
            "profile": fixture["profile"],
            "readstat": readstat,
            "pspp": pspp_result,
        })
    passed = {key: sum(r[key]["status"] == "supported_pass" for r in results)
              for key in ("readstat", "pspp")}
    disagreements = [r["file"] for r in results if r["pspp"].get("classification")]
    readstat_disagreements = [r["file"] for r in results if
                              r["readstat"].get("independent_byte_transport") == "supported_pass"
                              and r["readstat"].get("classification") == "readstat_default_cp1258_names_disagree"]
    summary = {"build": json.loads((ROOT / "lib/build.json").read_text()), "python": sys.version.split()[0],
               "pspp": subprocess.check_output([binary(), "--version"], text=True).splitlines()[0],
               "files": len(results), "pairs": len(results) // 2, "passed": passed,
               "pspp_disagreements": disagreements, "readstat_disagreements": readstat_disagreements,
               "results": results}
    (out / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps({key: summary[key] for key in
                      ("files", "pairs", "passed", "readstat_disagreements", "pspp_disagreements")}))
    readstat_ok = passed["readstat"] + len(readstat_disagreements) == len(results)
    pspp_ok = passed["pspp"] + len(disagreements) == len(results)
    return 0 if readstat_ok and pspp_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
