"""Generate strict Node mappings and public synthetic SAV fixtures, offline."""
import hashlib
import importlib
import json
from pathlib import Path
import platform
import struct

from fixture_writer import I, extension, sav

ROOT = Path(__file__).resolve().parents[1]
PROFILES = {
    874: "ยินดี",
    1250: "Žluť",
    1251: "Москва",
    1253: "Αθήνα",
    1254: "İzmir",
    1255: "שלום",
    1256: "عربي",
    1257: "Rīga",
    1258: "Ha\u0300 Nô\u0323i",
}


def main():
    tables = {}
    sources = {}
    fixtures = ROOT / "fixtures/synthetic/windows-codepages"
    fixtures.mkdir(exist_ok=True)
    manifest = []
    for code, sample in PROFILES.items():
        codec = f"cp{code}"
        name = f"windows-{code}"
        module = importlib.import_module(f"encodings.{codec}")
        sources[codec] = hashlib.sha256(Path(module.__file__).read_bytes()).hexdigest()
        tables[name] = [None if ch == "\ufffe" else ord(ch) for ch in module.decoding_table[128:]]
        marker = extension(3, b"".join(I(x) for x in [1, 0, 0, -1, 1, 1, 2, 2]), 4)
        for encoding in [codec, "utf-8"]:
            raw = sample.encode(encoding)
            variables = [
                {"name": "ID", "width": 4},
                {"name": "SCORE", "missing": [99.], "label": raw, "labels": [(99., raw)]},
                {"name": "NOTE", "width": len(raw), "label": raw},
            ]
            local = encoding == codec
            filename = f"{name}.sav" if local else f"{name}-utf8.sav"
            body = sav(variables, [[b"0012", 88., raw], [b"NA", 99., raw], [b"\\N", None, raw]],
                       encoding=name if local else "UTF-8", compressed=True)
            if local:
                assert body.count(marker) == 1
                body = body.replace(marker, marker[:-4] + struct.pack("<i", code), 1)
            (fixtures / filename).write_bytes(body)
            manifest.append({"file": filename, "profile": name if local else "utf-8",
                             "codepage": code, "expected_text": sample,
                             "sha256": hashlib.sha256(body).hexdigest()})
    data = {"source": f"CPython {platform.python_version()} strict encodings",
            "source_sha256": sources, "upper_half": tables}
    (ROOT / "node/windows-codepages.json").write_text(json.dumps(data, indent=2) + "\n")
    (fixtures / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
