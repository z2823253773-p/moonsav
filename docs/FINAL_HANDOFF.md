# MoonSav technical acceptance, date correction and freeze — 2026-11-06

Workspace `/Users/henryz/Desktop/比赛/moonsav`, private implementation branch. Frozen corrected source `5c1ff8dc7fa6ea8ea65b9849f5bb921db602856b`; digest `be4b72b90a6bdc927b085da3e89e477ce239f45cb2fb388251d5b271d41def71`; clean build. Later report commits do not change packaged source/README/CONTRACTS. Live HEAD/upstream/tracked status in ignored dist/delivery-state.json; docs/acceptance remains untracked and untouched.

**Accepted baseline:** original designated docs/acceptance/2026-11-06/REPORT.md gives PASSED_WITH_NOTES for exact e453463 archives, replacing its old waiting/CHANGES_REQUIRED state. The original Oct24 failure report remains. Baseline report SHA, exact hashes and remaining P3 notes are bound in evidence/date-warning-20261106/acceptance-baseline.json. This is product technical acceptance, not competition preliminary approval. No new report has transferred exact-byte approval to the following new hashes.

**Correction:** explicit GNU date/time codes20–30/38–41, numeric print OR write, once per variable;31–37 numeric/currency no date warning. Raw negativezero/missing/print/write remain preserved; no automatic dates. Old bundle warnings are inherited, so regenerate from SAV to correct historical false positives. README now has actual cross-platform evidence and `_` environment workaround. Source review had no actionable finding;512 numeric/15 string probes and strict precommit/inheritance behavior passed.

| Exact current archive under dist | Bytes | SHA256 |
| --- | ---: | --- |
| moonsav-0.1.0.tgz | 311136 | `2d6396266353c5b5f429427a823ed358eebf2ae1403d6abaa36e8c0a9db29ee1` |
| moonsav-source-0.1.0.zip | 75195 | `dc5d7e509582b687018cacaa066461a16ae23ab338065fdfa6a1668269098dff` |

Both declared toolchains138 Node and16 core per JS/native/wasm-gc. Clean local and Linux full entry17pass+29 expected bad vectors; public65449-cell ReadStat/PSPP comparison no unexplained difference. Both unchanged designated scripts pass against exact tgz (new date8 commands and original14 commands). Independent offline exact archive consumption and both-toolchain source consumers pass. [New CI](https://github.com/z2823253773-p/moonsav/actions/runs/42255719356) all4 jobs success; Windows127 shared/16 JS+wasm-gc, Linux/macOS138 Node/16 each3 core. Per-runner self-built artifacts differ from exact local bytes consumed on macOS; M4 records scope and retained oracle limits.

Technical submission candidate sealed at `dist/submission/moonsav-0.1.0-20261106-5c1ff8d` with both archives, SHA256SUMS, artifact manifest and compact verification/baseline records. Read docs/SUBMISSION_FREEZE.md. No event submission or public release occurred; future contest requirements must be checked separately before actual submission. A new exact-archive designated verdict has not been issued; do not describe initial technical acceptance as pending or imply the old exact approval covers the rebuilt bytes.

## Reproduction

Use a new output path; root dist is ignored by Git, so fresh clones need verified exact archives copied in for exact-byte challenge. Rebuilding changes hashes/provenance.

```sh
.dev/venv/bin/python docs/acceptance/2026-11-06/reproduce_format_warning.py --root . --output .dev/date-reaccept-NEW
.dev/venv/bin/python docs/acceptance/2026-10-24/reproduce_findings.py --root . --output .dev/original-reaccept-NEW
```

For clean source verification on this host:

```sh
git clone --no-hardlinks /Users/henryz/Desktop/比赛/moonsav /tmp/moonsav-date-reaccept-NEW
cd /tmp/moonsav-date-reaccept-NEW
PATH="/Users/henryz/Desktop/比赛/moonsav/.dev/moon-ci/bin:$PATH" MOONSAV_PSPP="/Users/henryz/Desktop/比赛/moonsav/.dev/pspp/bin/pspp" /Users/henryz/Desktop/比赛/moonsav/.dev/venv/bin/python tools/verify.py --all --require-public --require-pspp --output .cache/date-reaccept-NEW
```

Existing fixed dev tools/interpreter/cache reused, not a fresh-machine setup claim; other systems need platform-native declared tools. Old Moon consumer may require `env -u _ moon run . --target js` if a malformed environment path triggers its known crash; no toolchain modification. Acceptance-owned scripts/reports are local and intentionally not staged; preserve failure history and raw evidence. Consumers see full contracts in both archives.
