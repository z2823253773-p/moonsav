# Current contract repair — 2026-11-05

User asked whether all objects/input/output are explicit and requested continued improvement. Live HEAD da4ddb5 still has designated acceptance CHANGES_REQUIRED (docs/acceptance/2026-10-24/REPORT.md). All F1–F5 counterexamples reproduced against the original tgz in .dev/contracts-20261105/archive-red, exit1. Historical CI and normal-path success do not close these defects.

Candidate repair now passes108 Node tests and14 core tests each JS/native/wasm-gc on both declared toolchains. Contract docs cover all supported public models and boundaries; independent code-review fixes are included. Fresh clean-clone/full/oracle/archive/remote checks are pending.

Current plan: docs/superpowers/plans/2026-11-05-contract-hardening.md. Preserve acceptance-side files read-only/untracked, repair in sole-writer implementation checkout, add boundary regressions and comprehensive object/I/O contract, then rebuild/replay/full oracles/new-SHA CI and independent review. No further design approval or private push approval is needed; public release/registration remain outside scope.

---

# MoonSav current state

Updated2026-10-24 America/Phoenix. User explicitly authorized private repository creation, push and Actions. Repository: https://github.com/z2823253773-p/moonsav ; private=true verified before push and after verification. Branch implementation. Source candidate `0afbe3443a93f6fd13e7211ba41cc970ca0b00a9`; subsequent report commit changes only documentation/evidence. Exact current HEAD/dirty/upstream is in ignored dist/delivery-state.json and must be rechecked live.

- Final remote run40073319985 SUCCESS: Windows2025, Ubuntu24.04, macOS15 platform jobs and independent Linux oracles all passed at the same source SHA. Downloaded original state/logs/aggregate artifact plus cross-check are in evidence/remote-ci-final. CI URL: https://github.com/z2823253773-p/moonsav/actions/runs/40073319985
- Full local entry and remote Linux entry both:17 supported_pass + AC09 expected_rejection29 vectors; zero supported_fail/unexpected_result/not_run. Local/Linux/macOS49 Node tests (38 shared +11 POSIX); Windows38 shared tests. Core7/7 each JS/native/wasm-gc on local/Linux/macOS; Windows7/7 each JS/wasm-gc. Windows native/POSIX interruption behavior is not claimed.
- Exact local final npm/source archives were independently installed/extracted and consumed. Build SHA0afbe3443a93f6fd13e7211ba41cc970ca0b00a9, dirty=false, source_tree_sha2567a8e46aa59fb754213a574d807b316c42648e9ebcd861f9c5f38526db090869f. Final hashes/sizes in docs/delivery-manifest.json. Earlier8ae93f2 archives preserved unchanged in dist/history/8ae93f2. Later failed trial hashes are not delivery hashes.
- Current build profiles: original moon0.1.20260713/moonc0.10.4+2cc641edf and isolated/CI moon0.1.20261023/moonc0.10.17+d971670cd. Both passed local49 Node +7 per core backend and U1 consumer. Old official downloads403; new exact version/core downloaded and hashed under .dev without modifying original installation. Shared string.parse_double and native consumer workspace work with both.
- Two licensed real public files fully compared with ReadStat/PSPP:634x88 +87x111=65449 cells; no unexplained differences. Raw data/bundles remain ignored. Encoding profile limits/space normalization and Mac supplementary-plane oracle limitation remain explicit; no compatibility percentage or claim covering all SAV.
- Both initial remote failures are retained: first setup403/Windows NUL filename; second Windows shell argv loss/source consumer obsolete JSON config. Confirmed fixes were regression-tested/reviewed. See docs/progress/REMOTE_CI.md and evidence/remote-ci-first, remote-ci-second. CI provenance now records actual platform/run instead of hardcoded macOS/not_run.
- Product/artifacts are frozen; only reporting work follows. No further source rebuild is needed for documentation-only commits. No public npm/Mooncakes release or competition registration performed. No private research samples used/uploaded.
- **Designated acceptance remains pending.** Original chat01a168c9-225e-74c2-9868-7ffce7a79cd7 owns docs/acceptance and must independently approve/reproduce. Agent review is not its approval or external-user feedback. Start from docs/FINAL_HANDOFF.md, M4/M5 and current manifest. Do not write approval on its behalf.
