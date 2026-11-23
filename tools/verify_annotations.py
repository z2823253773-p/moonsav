"""Verify one PSPP-produced file and two synthetic dictionary grammar cases."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

from capture import capture
from compare_oracle import compare
from pspp_oracle import binary

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    out = parser.parse_args().output.resolve()
    out.mkdir(parents=True)
    versions = subprocess.check_output([binary(), "--version"], text=True).splitlines()[0]
    results = []
    for stem in ("annotations-pspp", "annotations-varsets", "annotations-mrsets"):
        source = ROOT / "fixtures/synthetic" / (stem + ".sav")
        log = out / stem
        bundle = log / "payloads" / "bundle"
        bundle.parent.mkdir(parents=True)
        for command in (["export", str(source), "--out", str(bundle)], ["check-bundle", str(bundle)]):
            code, _, _ = capture(["node", "bin/moonsav.mjs", *command, "--json"], log)
            if code:
                raise RuntimeError(f"{stem} {command[0]} exited {code}")
        readstat = compare(source, bundle)
        assert readstat["status"] == "supported_pass", readstat
        metadata = json.loads((bundle / "metadata.json").read_text(encoding="utf-8"))
        annotations = metadata["dictionary_annotations"]
        results.append({
            "file": source.name,
            "sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "readstat_values_and_dictionary": readstat["status"],
            "decoded_records": [(r["record"], r["subtype"]) for r in annotations["sources"]],
        })
        if stem == "annotations-pspp":
            syntax = log / "readback.sps"
            path = str(source).replace("'", "''")
            syntax.write_text(f"GET FILE='{path}'.\nDISPLAY DOCUMENTS.\nDISPLAY ATTRIBUTES.\nMRSETS /DISPLAY NAME=ALL.\n")
            code, stdout, _ = capture([binary(), "-O", "format=csv", "--batch", str(syntax)], log)
            assert code == 0
            file_values = [value for a in annotations["file_attributes"] for value in a["values"]]
            set_labels = [s["label"] for s in annotations["multiple_response_sets"]]
            notes = [line.rstrip() for line in annotations["document_lines"][:2]]
            per_variable = [value for group in annotations["variable_attributes"]
                            for a in group["attributes"] if a["name"] == "Units" for value in a["values"]]
            for value in notes + file_values + per_variable + set_labels:
                assert value in stdout, (value, stdout)
    report = {"pspp": versions, "build": json.loads((ROOT / "lib/build.json").read_text()),
              "files": results, "ibm26_oracle": "pending"}
    (out / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
