"""Reproduce the ZSAV milestone against shipped fixtures and two parser families.

This is developer compatibility evidence, not IBM26 or organizer acceptance.
"""
import argparse
import json
import subprocess
from pathlib import Path
import pyreadstat
from capture import capture
from compare_oracle import compare
from pspp_oracle import compare as pspp_compare

ROOT = Path(__file__).resolve().parents[1]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', required=True)
    args = p.parse_args()
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=False)
    payloads = out / 'payloads'
    payloads.mkdir()
    results = []
    modes = ['zsav-survey-none.sav', 'zsav-survey-row.sav', 'zsav-survey-zlib.zsav',
             'zsav-zero.zsav', 'zsav-produced-multi.zsav', 'zsav-multi.zsav']
    for name in modes:
        source = ROOT / 'fixtures/synthetic' / name
        bundle = payloads / name
        code, _, _ = capture(['node', 'bin/moonsav.mjs', 'export', str(source), '--out', str(bundle), '--json'],
                             out / name / 'export', inputs=[source])
        if code:
            raise RuntimeError(f'export {name}: {code}')
        code, _, _ = capture(['node', 'bin/moonsav.mjs', 'check-bundle', str(bundle), '--json'], out / name / 'check')
        if code:
            raise RuntimeError(f'check-bundle {name}: {code}')
        row = {'fixture': name}
        try:
            row['readstat'] = compare(source, bundle)
            if row['readstat']['status'] != 'supported_pass':
                raise RuntimeError(f'ReadStat difference: {name}')
        except pyreadstat.ReadstatError as e:
            if name != 'zsav-multi.zsav':
                raise
            row['readstat'] = {'status': 'oracle_disagreement', 'message': str(e),
                               'scope': 'handcrafted 13-byte block / nondefault bias vector; not counted as ReadStat pass'}
        if name != 'zsav-zero.zsav':
            row['pspp'] = pspp_compare(source, bundle, out / name / 'pspp')
            if row['pspp']['status'] != 'supported_pass':
                raise RuntimeError(f'PSPP difference: {name}')
        else:
            row['pspp'] = {'status': 'not_run', 'reason': 'zero-row vector covered by MoonSav and ReadStat; not a PSPP compatibility claim'}
        results.append(row)
    # This comparison includes every Cell and every variable dictionary field.
    cross = []
    for name in modes[:3]:
        b = payloads / name
        metadata = json.loads((b / 'metadata.json').read_text())
        cross.append(((b / 'data.ndjson').read_bytes(), metadata['variables']))
    if not (cross[0] == cross[1] == cross[2]):
        raise RuntimeError('cross-storage semantic difference')
    report = {'milestone': 'ZSAV little-endian IEEE754', 'same_survey_cross_storage_equal': True,
              'pyreadstat': pyreadstat.__version__,
              'build': json.loads((ROOT / 'lib/build.json').read_text()),
              'sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'results': results,
              'not_proven': ['IBM26 original producer/readback', 'big endian', 'all IBM26 codepages',
                             'full dictionary semantics', 'password protection', 'new remote CI', 'organizer acceptance']}
    (out / 'summary.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'same_survey_equal': True, 'fixtures': len(results),
                      'readstat_passes': sum(x['readstat']['status'] == 'supported_pass' for x in results),
                      'pspp_passes': sum(x['pspp']['status'] == 'supported_pass' for x in results),
                      'oracle_disagreements': [x['fixture'] for x in results if x['readstat']['status'] == 'oracle_disagreement']},
                     ensure_ascii=False))


if __name__ == '__main__':
    main()
