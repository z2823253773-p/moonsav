# Exact artifact consumption

Result: **passed**, 2026-11-06, macOS 26.4 arm64. This consumes the supplied final archives without rebuilding or repackaging them. It is not designated acceptance approval.

| Archive | Bytes | Verified SHA256 |
| --- | ---: | --- |
| `moonsav-0.1.0.tgz` | 310035 | `9817d55a6880693ecaf615c3ce7da721b4eda951202371c2d410588bb29f5bc7` |
| `moonsav-source-0.1.0.zip` | 73493 | `a5f7ad5ae55a0a81755d2cbc01e788960c0ba7bdf3a16481f0972f9119b35618` |

The tested byte copies are preserved here. Originals came from `.dev/stream-cleanup-20261106/clean-candidate/dist`. `consume.py` verifies the supplied hashes and sizes before copying, installing, or extracting them.

## Installed Node package

Fresh consumer directory and initially absent npm cache. Installation command uses `--offline --ignore-scripts --no-audit --no-fund` and the exact tarball. Its environment PATH contains only a symlink to Node; MoonBit and Python are absent from PATH. Node runtime is v24.15.0 / ICU 78.2.

All commands exit 0: install, `--version`, `inspect`, `validate`, `export`, `check-bundle`, and the installed `examples/read_bundle.py`. Inspection reports dictionary-only rows null; validation/export/check each report 5 rows. The packaged Python reader independently consumes canonical plus CSV and reports 5 rows, 13 present cells. The bundle output path contains spaces and Chinese characters.

Packaged build metadata reports `dirty=false`, git SHA `e453463ae8206fffb8a6fae860168d4a2be8c6ae`, source-tree SHA256 `f1334fe3947b42e0dba4e70a6ac3f5340b25c6498e1da3ca756004fc7cc0dfd7`, Moon 0.1.20261023 / moonc v0.10.17+d971670cd. Version output agrees with `lib/build.json`.

## Exact source package

The source ZIP was freshly extracted into separate directories for the two toolchains. Its shipped `examples/consumer/moon.work` resolves both consumer and source module locally (`members = [".", "../.."]`). No source modifications were made.

| Toolchain | JS consumer | Native consumer | Wasm-GC consumer |
| --- | --- | --- | --- |
| Moon 0.1.20260713 / moonc v0.10.4+2cc641edf | exit 0 | exit 0 | exit 0 |
| Moon 0.1.20261023 / moonc v0.10.17+d971670cd | exit 0 | exit 0 | exit 0 |

All six runs print the shipped U1 success assertion: labels, unlabeled valid value, ID text, missing filter, retained rows, Stop and consumer failure passed.

## Evidence and limits

`result.json` records all 15 commands with absolute arguments, working directories, exit codes, durations, selected environment and individual stdout/stderr log paths. All 15 exit 0. `run.log` contains the compact result, and `consume.py` is the exact harness used. The harness is intentionally first-run-only so rerunning cannot silently reuse an existing consumer/cache.

Only the npm install explicitly enforces offline mode; no network isolation sandbox was applied to runtime or compiler commands. They use shipped Node code, local source modules and installed core toolchains. The Python reader was run with local Python 3.14, not a claim of separate Python 3.12 validation. This work does not repeat the parent's clean full suite, designated F1-F5 replay, or CI, and does not substitute for those results.
