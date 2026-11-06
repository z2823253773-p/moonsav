# MoonSav current state — 2026-11-06

Frozen product `e453463ae8206fffb8a6fae860168d4a2be8c6ae`; source digest `f1334fe3947b42e0dba4e70a6ac3f5340b25c6498e1da3ca756004fc7cc0dfd7`. Private repository https://github.com/z2823253773-p/moonsav , branch implementation. Later reporting commits leave packaged product bytes frozen; live HEAD/upstream/status are in ignored dist/delivery-state.json.

Current repair closes a real CSV generator descriptor leak on failed bundle checks. Four real-fd regressions went RED→GREEN. Independent source review compared11 success/failure paths, preserving errors/results and leaving zero descriptors; the same11 paths passed against the exact rebuilt tgz runtime. No new formats or options were added. All public object/I/O contracts remain in docs/CONTRACTS.md; prior F1–F5 counterexamples still pass on the new tgz.

- Both declared compiler/core pairs:112 Node tests,14 core tests each JS/native/wasm-gc locally. Python harness unittest1 passed.
- Clean committed clone full AC01–18:17 supported_pass + AC09 expected_rejection29 vectors, zero failures/unexpected/not_run. Two public SAV files65449 cells compare with ReadStat/PSPP with no unexplained differences; normalizations and Mac supplementary-plane oracle limitation remain explicit.
- New [run42248646372](https://github.com/z2823253773-p/moonsav/actions/runs/42248646372) SUCCESS, all4 jobs: Windows2025, Ubuntu24.04, macOS15, Linux independent oracles. Windows101 shared Node tests and14 core JS/wasm-gc; Linux/macOS112 Node and14 per JS/native/wasm-gc. Windows native/POSIX is outside claimed scope.
- Clean-build exact tgz/source zip and their new SHA256 are in docs/delivery-manifest.json; prior candidates are preserved in dist/history. Independent exact archive commands all exit0; report in evidence/stream-cleanup-20261106/independent-review/archive-consumer-result.json. Both fixed toolchains consume the source archive.
- Tracked product clean is distinct from untouched/untracked docs/acceptance. Original designated CHANGES_REQUIRED remains historical pending new-candidate re-acceptance. Agent review does not approve on its behalf.

Read docs/FINAL_HANDOFF.md, M4/M5 and docs/progress/STREAM_CLEANUP.md. No public registry release, competition registration, organizer approval or external-human trial occurred. Existing private push/Actions authorization persists.
