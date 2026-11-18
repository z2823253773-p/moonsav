"""Generate big-endian public synthetic counterparts; never imports MoonSav."""
import hashlib
import json
from pathlib import Path
import platform
import struct
import zlib
from convert_endian import to_big_endian
from fixture_writer import sav, extension, I, D

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'fixtures/synthetic'
SOURCES = ['zsav-survey-none.sav', 'zsav-survey-row.sav', 'zsav-survey-zlib.zsav',
           'controls.sav', 'controls-unknown.sav', 'negative-zero.sav', 'range.sav',
           'lowest-highest.sav', 'date-display.sav', 'semantics-9.sav',
           'semantics-256.sav', 'semantics-505.sav', 'zsav-zero.zsav']


def main():
    # Extra integer64/sentinel/weight fields absent from the shared survey.
    extra = (extension(4, struct.pack('<QQQ', 0xffefffffffffffff, 0x7fefffffffffffff, 0xffeffffffffffffe), 8)
             + extension(16, struct.pack('<QQ', 1, 3), 8)
             + extension(11, I(3) + I(12) + I(1), 4))
    source = bytearray(sav([{'name': 'SCORE', 'missing_count': -3, 'missing': [1., 2., 99.],
                             'labels': [(99., b'User missing')]}], [[1.], [99.], [None]], extensions=extra))
    struct.pack_into('<i', source, 76, 1)
    (OUT / 'endian-extra-le.sav').write_bytes(source)
    (OUT / 'endian-signed-zero-le.sav').write_bytes(sav([{'name': 'NUMBER'}], [[-0.0], [0.0], [1.25]]))
    pairs = []
    for name in SOURCES + ['endian-extra-le.sav', 'endian-signed-zero-le.sav']:
        path = OUT / name
        target = OUT / ('be-' + name)
        target.write_bytes(to_big_endian(path.read_bytes()))
        pairs.append({'source': name, 'big_endian': target.name,
                      'source_sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                      'big_endian_sha256': hashlib.sha256(target.read_bytes()).hexdigest()})
    report = {'producer': 'independent Python GNU-layout endian conversion of synthetic fixtures',
              'not_ibm_proof': True, 'python': platform.python_version(), 'zlib': zlib.ZLIB_VERSION,
              'pairs': pairs}
    (OUT / 'endian-provenance.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'pairs': len(pairs), 'not_ibm_proof': True}))


if __name__ == '__main__':
    main()
