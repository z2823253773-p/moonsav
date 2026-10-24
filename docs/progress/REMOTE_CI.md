# Remote CI continuation

2026-10-24 America/Phoenix. User explicitly authorized creation of a private MoonSav repository, pushing the current code, and running Actions. GitHub connector and CLI both identify z2823253773-p; connector cannot see the newly created private repo, so gh CLI performs supported repo/Actions operations. No public release or registration is included.

Repository https://github.com/z2823253773-p/moonsav was created; private=true/visibility=private were verified before first push. implementation first pushed at45f5ff2f19db8b4be469d6cdecb5df4077837998. Run https://github.com/z2823253773-p/moonsav/actions/runs/40071770062 failed before product tests. Ubuntu/macOS download old MoonBit binary/core URL403; Windows checkout rejected fixtures/synthetic/nul.sav (NUL reserved). Failures are actual remote evidence, not compatibility passes.

Investigation: official current fixed0.10.17+d971670cd archives and core return200; both historical hosts and candidate old version spellings403. Installed original toolchain remains intact. New Darwin archive/core were downloaded into ignored .dev/moon-ci, hashed, permissions set, core bundled. The first direct check without bundling failed for missing std interfaces (setup experiment, retained); after bundling exactly one source incompatibility remained: removed deprecated strconv.parse_double. string.parse_double is present in both pinned cores; the minimal import/call change passed both versions.

New build guard permits only the two exact moon/moonc pairs declared in toolchain.json and records actual compiler versions. CLI version previously falsely repeated old constants on a new build; a failing regression now passes. NUL fixture bytes are unchanged; generator/manifest/test live references renamed. The existing Windows checkout is the failing integration test, and the corrected checkout will be the acceptance proof.

Both local toolchains passed49 Node tests and7 core tests per JS/native/wasm-gc. Source archive inspection still includes its standalone consumer; the suspected modern packaging regression was not reproduced and no packaging workaround was added. Acceptance-runner metadata formerly hardcoded macOS/not_run even when run by Linux Actions; a real entry regression caught this and now passes with actual system/architecture, CI flag/runner label/run URL. Per-job metadata never claims other workflow jobs or designated acceptance passed.

All first-run job state/logs, HTTP probes, isolated archive hashes, local red/green and setup failures are preserved in evidence/remote-ci-first. Current workflow results remain pending until a new run reaches and passes actual product/oracle/install tests. Final artifact hashes and branch state will be updated only after verification.

## Second actual run

Run40072702661 atb20b15f: Ubuntu and macOS platform jobs succeeded. Windows shared corpus and JS/wasm-gc core checks succeeded but first-use npm pack failed EINVALIDTAGNAME because shell mode split the intentional Chinese/space directory; the independent reviewer reproduced the same argument error. Fixed by invoking npm JavaScript CLI through Node with argument arrays and no shell; local real archive smoke passed.

Independent Linux full entry completed13 supported_pass + AC09 expected rejects, with four package-dependent failures (AC08/12/14/17) from modern Moon rejecting consumer moon.mod.json/local path configuration. The same failure was reproduced locally. Migrated only example configuration to native moon.mod/moon.pkg and local moon.work, per official dependency-management docs; root archive includes them. Actual regenerated archive install and extracted consumers on JS/native/wasm-gc passed; direct U1 also passed on both toolchains/three backends. README now uses the workspace contract.

Raw second-run jobs, downloaded aggregate artifact, local full failure, reviewer characterization and corrected package logs are in evidence/remote-ci-second. Original delivered archives remain unchanged in dist/history/8ae93f2; dist root currently holds the newer candidate. A final clean committed build/run is still required; intermediate package hashes are not final.

The independent agent rechecked the corrected shell-free smoke, old U1, modern build/source archive and extracted U1 across all three local backends; no further concrete issue found. Evidence: remote-ci-second/reviewer-final/report.json. This is local agent proof only. toolchain.json points to per-run evidence rather than freezing a mutable CI status into each build profile.

## Final verified run

2026-10-24: run40073319985 at0afbe3443a93f6fd13e7211ba41cc970ca0b00a9 completed SUCCESS on all four jobs. Original API state/logs/downloaded aggregate artifact and private repo metadata are in evidence/remote-ci-final. Independent Linux summary has17 supported_pass + AC09 expected_rejection29, zero failures/unexpected/not_run. Windows38 shared + JS/wasm-gc, Linux/macOS49 tests +three core backends and own offline archive smoke all passed. Full local entry also passed with the same source digest and clean build. No conditional omissions are counted as passes.

Downloaded Linux package metadata source_tree_sha256 matches local7a8e46aa59fb754213a574d807b316c42648e9ebcd861f9c5f38526db090869f. Linux dirty=true records generated untracked evidence only; local delivered build dirty=false. Final local archive hashes and independent exact-archive checks are in docs/delivery-manifest.json and evidence/remote-ci-final/independent-artifacts. Current M4/M5/FINAL_HANDOFF replace the earlier pending delivery state. Overall designated acceptance remains separate and pending.
