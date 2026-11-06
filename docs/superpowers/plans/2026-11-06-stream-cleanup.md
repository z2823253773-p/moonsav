# Bundle checker stream cleanup implementation plan

> Execute inline in the existing sole-writer implementation checkout. Apply executing-plans, then a fresh end review. This is a repair of existing resource ownership, authorized by continuation; no new product or format scope.

**Goal:** A failed CSV+canonical bundle check releases every opened file descriptor before returning/throwing.
**Architecture:** Keep MoonBit semantic checking unchanged. The Node filesystem adapter owns its CSV iterator and must close it in a finally block. Continue using generator-owned descriptor cleanup; do not swallow the original semantic error.
**Tech:** Existing pinned Node24.15.0 and both declared MoonBit toolchains.
**Spec:** docs/CONTRACTS.md file/state/ownership boundaries and existing CLI resource contract.

## Review focus

Header rejection, canonical-row rejection, CSV framing rejection and mismatched record counts must all close the CSV generator; successful checks must remain unchanged. Iterator construction must remain lazy and errors must preserve the original classification.

- [x] Add tests with real exported bundles and delegated fs.openSync observation; after each failed check, fstatSync on every observed CSV/NDJSON descriptor must fail EBADF. Closing descriptor in the test cleanup is only to contain pre-fix leaks.
- [x] Observe the expected resource leak RED against current code; retain output.
- [x] Wrap ownership scope in try/finally and call csv?.return(); run focused and whole Node suite.
- [x] Review corrected diff, commit candidate, run both toolchains/core and clean-clone full entry; rebuild archives, replay designated counterexamples and run new-SHA private CI.
- [x] Preserve previous exact artifacts under dist/history/a3c4b22; update manifest/current state/handoff/evidence after successful checks. Original acceptance directory remains untracked and untouched.

Ledger2026-11-06: four real-fd RED cases reproduced on 3f65f3a/a3c4b22 source. Initial header test used an uppercase field token absent from the fixture; corrected to alter the actual header before observing all four expected leak failures (red-2.log). Minimal try/finally cleanup passes4/4 and full112/112. Existing implementation checkout retained to preserve sole writer/acceptance-owned files; private push authorization already covers later source commit/CI. No new scope or design-selection round is required for this resource cleanup.

Independent review: no actionable findings;11 real-I/O paths preserve result/error code/message and leave zero descriptors, complete bundle suite21/21. Review limits: OS close failures and OS interruption are not proven by this deterministic synchronous check; existing POSIX interruption corpus and platform-specific limitations remain in force. No new retry or close-error precedence policy is introduced by this repair.

Delivery integration follows persistent session authorization: keep the implementation branch and private origin push/Actions; no merge, new PR, release or workspace deletion. Exact source-only candidate lib/build metadata copied from the verified clean clone into ignored root lib so local CLI version is consistent with delivered bytes.

Final2026-11-06: source e453463, both profiles112 Node +14 core per backend; clean full entry17pass+29bad, new tgz unchanged F1–F5 replay pass and exact-runtime11-path cleanup replay pass. Independent exact archive consumption and remote42248646372 all4 jobs pass. Previous a3c4b22 packages retained; current manifest/handoff/evidence updated. No designated acceptance approval was self-granted.
