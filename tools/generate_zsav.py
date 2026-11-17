"""Public synthetic-only ZSAV fixtures; no MoonSav parser is imported.

pyreadstat is the independent SAV producer. The small multiblock fixture is
written from the GNU PSPP container layout around the existing opcode vector.
"""
from pathlib import Path
import hashlib
import json
import platform
import struct
import zlib
import pandas as pd
import pyreadstat
from fixture_writer import sav

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'fixtures/synthetic'


def wrap(prefix, stream, block_size):
    prefix = bytearray(prefix)
    prefix[:4] = b'$FL3'
    struct.pack_into('<i', prefix, 72, 2)
    base = len(prefix)
    parts = [stream[i:i + block_size] for i in range(0, len(stream), block_size)]
    if not parts:
        parts = [b'']
    packed = [zlib.compress(part) for part in parts]
    trailer = base + 24 + sum(map(len, packed))
    desc = []
    uofs, cofs = base, base + 24
    for raw, compressed in zip(parts, packed):
        desc.append(struct.pack('<qqii', uofs, cofs, len(raw), len(compressed)))
        uofs += len(raw)
        cofs += len(compressed)
    bias = struct.unpack_from('<d', prefix, 84)[0]
    return (bytes(prefix) + struct.pack('<qqq', base, trailer, 24 + 24 * len(parts))
            + b''.join(packed)
            + struct.pack('<qqii', -int(bias), 0, block_size, len(parts))
            + b''.join(desc))


def main():
    frame = pd.DataFrame({
        'subject_code': ['0012', 'NA', '\\N'],
        'group': [1., 2., 1.],
        'score': [88., 99., None],
        'answer': ['Y', 'N', 'X'],
        'long_note': ['问卷备注' * 140 + str(i) for i in range(3)],
        'visit_date': [1e9, 1e9 + 86400, 1e9 + 172800],
    })
    opts = dict(column_labels=['编号', '分组', '得分', '回答', '长备注', '访问日期'],
                variable_value_labels={'group': {1.: '甲组', 2.: '乙组'},
                                       'answer': {'Y': '是', 'N': '否', 'X': '未答'}},
                missing_ranges={'score': [99.], 'answer': ['X']},
                variable_format={'visit_date': 'DATE11'})
    paths = []
    for mode, flags, suffix in [('none', {}, '.sav'), ('row', {'row_compress': True}, '.sav'),
                                ('zlib', {'compress': True}, '.zsav')]:
        path = OUT / ('zsav-survey-' + mode + suffix)
        pyreadstat.write_sav(frame, str(path), **opts, **flags)
        paths.append(path)
    zero = OUT / 'zsav-zero.zsav'
    pyreadstat.write_sav(pd.DataFrame({'value': pd.Series([], dtype='float64')}), str(zero), compress=True)
    paths.append(zero)
    produced_multi = OUT / 'zsav-produced-multi.zsav'
    pyreadstat.write_sav(pd.DataFrame({'note': ['问卷备注' * 140 + f'{i:04d}' for i in range(3000)]}),
                        str(produced_multi), compress=True)
    paths.append(produced_multi)
    controls = (OUT / 'controls.sav').read_bytes()
    offset = len(sav([{'name': 'N'}, {'name': 'S', 'width': 8}], [], compressed=True, bias=7.)) - 8
    multi = OUT / 'zsav-multi.zsav'
    multi.write_bytes(wrap(controls[:offset], controls[offset:], 13))
    paths.append(multi)
    # Normalize synthetic header time only, so regeneration is byte-reproducible.
    for path in paths:
        b = bytearray(path.read_bytes())
        b[92:109] = b'17 NOV 26' + b'00:00:00'
        path.write_bytes(b)
    report = {'producer': 'pyreadstat/ReadStat; multiblock: independent Python GNU-layout writer',
              'not_ibm_proof': True, 'pyreadstat': pyreadstat.__version__, 'python': platform.python_version(),
              'zlib': zlib.ZLIB_VERSION, 'multiblock_data_offset': offset,
              'fixtures': {p.name: {'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
                                     'bytes': p.stat().st_size} for p in paths}}
    (OUT / 'zsav-provenance.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
