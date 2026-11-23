"""Run cross-encoding, CLI and independent-reader checks on the synthetic corpus."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import unicodedata

from capture import capture
from compare_oracle import compare
from pspp_oracle import binary, compare as compare_pspp

ROOT = Path(__file__).resolve().parents[1]


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
        pspp_result = compare_pspp(source, bundle, report / "pspp")
        if fixture["profile"] == "windows-1258":
            classify_pspp(pspp_result, expected, report / "pspp/payloads/oracle.csv")
        results.append({
            "file": source.name,
            "profile": fixture["profile"],
            "readstat": compare(source, bundle),
            "pspp": pspp_result,
        })
    passed = {key: sum(r[key]["status"] == "supported_pass" for r in results)
              for key in ("readstat", "pspp")}
    disagreements = [r["file"] for r in results if r["pspp"].get("classification")]
    summary = {"build": json.loads((ROOT / "lib/build.json").read_text()), "python": sys.version.split()[0],
               "pspp": subprocess.check_output([binary(), "--version"], text=True).splitlines()[0],
               "files": len(results), "pairs": len(results) // 2, "passed": passed,
               "pspp_disagreements": disagreements, "results": results}
    (out / "summary.json").write_text(json.dumps(summary, indent=2, ensure_ascii=False) + "\n")
    print(json.dumps({key: summary[key] for key in ("files", "pairs", "passed", "pspp_disagreements")}))
    all_explained = passed["readstat"] == len(results) and passed["pspp"] + len(disagreements) == len(results)
    return 0 if all_explained else 1


if __name__ == "__main__":
    raise SystemExit(main())
