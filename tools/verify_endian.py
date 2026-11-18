"""Reproducible developer endian validation; original IBM26 proof is still absent."""
import argparse
import json
from pathlib import Path
import subprocess
import pyreadstat
from capture import capture
from compare_oracle import compare
from pspp_oracle import compare as pspp_compare

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    out = Path(args.output).resolve()
    out.mkdir(parents=True, exist_ok=False)
    payloads = out / 'payloads'
    payloads.mkdir()
    provenance = json.loads((ROOT / 'fixtures/synthetic/endian-provenance.json').read_text())
    results = []
    for pair in provenance['pairs']:
        snapshots = []
        for name in [pair['source'], pair['big_endian']]:
            source = ROOT / 'fixtures/synthetic' / name
            bundle = payloads / name
            code, _, _ = capture(['node', 'bin/moonsav.mjs', 'export', str(source), '--out', str(bundle), '--json'],
                                 out / name / 'export', inputs=[source])
            if code:
                raise RuntimeError(f'export {name}: {code}')
            code, _, _ = capture(['node', 'bin/moonsav.mjs', 'check-bundle', str(bundle), '--json'], out / name / 'check')
            if code:
                raise RuntimeError(f'check-bundle {name}: {code}')
            reference = compare(source, bundle)
            if reference['status'] != 'supported_pass':
                # Existing extreme-value vector stores HIGHEST/LOWEST in data.
                # ReadStat tags both as system missing; MoonSav preserves them.
                # Keep the failed comparison visible; never count it as a pass.
                fields = [d['field'] for d in reference['differences']]
                if (name in ('negative-zero.sav', 'be-negative-zero.sav')
                        and fields == ['system_value', 'missing_kind', 'system_value', 'missing_kind']
                        and reference['normalizations']['system_missing_to_None'] == 2):
                    reference['classification'] = 'oracle_disagreement'
                    reference['reason'] = 'HIGHEST/LOWEST data values: ReadStat tags missing; MoonSav preserves raw finite bits. IBM26 behavior unverified.'
                else:
                    (out / 'failure.json').write_text(json.dumps({'fixture': name, 'readstat': reference}, indent=2) + '\n')
                    raise RuntimeError(f'ReadStat difference: {name}')
            row = {'fixture': name, 'readstat': reference}
            if name.startswith('be-') and name != 'be-zsav-zero.zsav':
                row['pspp'] = pspp_compare(source, bundle, out / name / 'pspp')
                if row['pspp']['status'] != 'supported_pass':
                    (out / 'failure.json').write_text(json.dumps(row, indent=2) + '\n')
                    raise RuntimeError(f'PSPP difference: {name}')
            else:
                row['pspp'] = {'status': 'not_run', 'reason': 'PSPP gate targets nonempty BE counterparts; no inferred pass'}
            results.append(row)
            metadata = json.loads((bundle / 'metadata.json').read_text())
            snapshots.append(((bundle / 'data.ndjson').read_bytes(), metadata['variables']))
        if snapshots[0] != snapshots[1]:
            raise RuntimeError(f'endian semantics mismatch: {pair["source"]}')
    report = {'milestone': 'matching integer/IEEE754 little and big endian', 'pairs_equal': len(provenance['pairs']),
              'results': results, 'pyreadstat': pyreadstat.__version__,
              'sha': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'build': json.loads((ROOT / 'lib/build.json').read_text()),
              'not_proven': ['IBM26 original producer/readback', 'IBM/VAX and arbitrary mixed integer/float order',
                             'all IBM26 encodings/dictionary semantics/password protection', 'new remote CI', 'organizer acceptance']}
    (out / 'summary.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({'pairs_equal': report['pairs_equal'], 'readstat_passes': sum(r['readstat']['status'] == 'supported_pass' for r in results),
                      'readstat_disagreements': [r['fixture'] for r in results if r['readstat']['status'] != 'supported_pass'],
                      'pspp_passes': sum(r['pspp']['status'] == 'supported_pass' for r in results)}))


if __name__ == '__main__':
    main()
