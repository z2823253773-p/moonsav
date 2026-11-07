# Node integration candidate handoff — 2026-11-07

Worktree `/Users/henryz/Desktop/比赛/moonsav/.dev/integration-20261107/worktree`; branch feature/node-integration. Frozen product `c89ce1aa9fdea8114fe0d8157ee4de043da66583`, digest `9284c43f6b4fa169869e0a44128c0acc0b44b59aeb7b933fd7551b5a50e96caa`, clean build. Later commits are reporting/evidence only; exact live HEAD/upstream/status in ignored dist/delivery-state.json. Original implementation checkout, accepted artifacts and untracked acceptance/submission materials remain untouched.

Original designated verdict PASSED for exact5c1ff8d is recorded by original docs/acceptance/CURRENT.json and2026-11-06-final/REPORT.md. Snapshot/report SHA in evidence/node-integration-20261107/accepted-baseline.json. New integration bytes do not inherit exact-byte approval.

New root API is `import {readSav,inspectSav,SavError} from 'moonsav'` or fixed-Node24 require; types resolve from the installed package, legacy CJS extension aliases remain working, and examples/read_sav.mjs reports real missing counts. No MoonBit source/data/date changes; TypeScript is dev-only. See README/CONTRACTS/FUNCTION_COVERAGE/NODE_INTEGRATION.

| Candidate archive in this worktree dist | Bytes | SHA256 |
| --- | ---: | --- |
| moonsav-0.1.0.tgz | 313794 | `9366c3d597d5c4b846d0caa6c3741a62186428187b0378b0f59c7b89d5b33b8e` |
| moonsav-source-0.1.0.zip | 76185 | `f92ef14cd516f171cd8680e2a2357258869648c2444fe96f7daccbb98c2a4aa5` |

Both toolchains142 Node and16 core per JS/native/wasm-gc; clean full17pass+29bad, public65449 cells no unexplained difference; both unchanged original challenge scripts green. Independent exact consumption22 commands exit0, including strict installed declarations and source consumers both pairs×three backends. New [CI42384344415](https://github.com/z2823253773-p/moonsav/actions/runs/42384344415) all4 jobs success. Windows131 shared/16 JS+wasm-gc, Linux/macOS142/16 each3 backend; per-runner own artifacts differ from exact local bytes consumed on macOS.

Fresh source verification requires `npm ci --ignore-scripts` before full runner because TypeScript is a dev test dependency. On this host prepend `/Users/henryz/Desktop/比赛/moonsav/.dev/moon-ci/bin`, use original .dev/venv Python and .dev/pspp/bin/pspp with fresh output; full-entry-command.json records actual paths/reuse. Clone this feature commit into a new path, install fixed dev deps, then tools/verify.py --all --require-public --require-pspp. Exact-byte consumption needs these verified archives copied separately; rebuild changes provenance/hashes. Original owner-controlled challenge scripts stay in original checkout and accept --root to this candidate.

Review P2 exports regression is repaired by tests; no remaining actionable finding. No new designated acceptance, merge or public/event submission. Integration candidate is ready for source review as a private draft PR; preserve accepted baseline until choosing integration.
