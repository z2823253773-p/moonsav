# Independent source review: checker stream ownership

Reviewed 2026-11-06 against base `3f65f3ac954b4556323ca711c31fe5b64e683aaa` plus the working-tree changes in `node/checker.mjs`, `tests/bundle.test.mjs`, and `docs/CONTRACTS.md`. Read `docs/superpowers/plans/2026-11-06-stream-cleanup.md` and the relevant contract boundaries. Runtime: Node v24.15.0, Darwin arm64.

Result: no actionable source correctness or regression finding within this change. This is an independent source review, not designated acceptance approval.

## Reasoning

- `csvRecords` opens lazily on first `next()` and owns its descriptor in its own generator `finally`. The new outer `try` starts before construction and the initial `next()`, so header failures and all later exits run `csv.return()`. An unstarted or already-completed generator has no live descriptor to close.
- The NDJSON generator remains owned by `for...of`: body exceptions invoke iterator close, and framing/decoding exceptions run its generator `finally`. Closing the separately-owned CSV generator covers the previously missing path without changing semantic calls or ordering.
- All tested original error codes and messages survive unchanged, including `IntegrityMismatch`, `InvalidEncoding`, and injected NDJSON-open `EIO`. The successful report is unchanged.
- The four added regressions use exported bundles with recomputed manifests, delegate real filesystem opens, verify real descriptor invalidity via `fstatSync(...): EBADF`, and contain baseline leaks in cleanup. They do not substitute a fake iterator or merely assert a close spy. Independently replaying the baseline shows each of these four inputs leaks one CSV descriptor and the candidate leaks none.
- No new format, semantic validation, or public option is introduced. The contract sentence states the ownership guarantee fixed here.

## Independent checks

1. `node --test --test-name-pattern='failed .* check closes' tests/bundle.test.mjs`: 4 passed, 0 failed; `focused.log`.
2. `node --test tests/bundle.test.mjs`: 21 passed, 0 failed; `bundle-suite.log`.
3. `node .dev/stream-cleanup-review-20261106/experiments.mjs`: 11 before/after comparisons, unchanged error code/message or success result, zero candidate leaks throughout. Full observations in `experiments.json`, compact results in `experiments.log`.

| Independent case | Baseline live data fds after return | Candidate live data fds after return |
| --- | ---: | ---: |
| Valid paired bundle | 0 | 0 |
| Wrong CSV header | 1 | 0 |
| Canonical JSON syntax | 1 | 0 |
| Canonical final newline absent | 1 | 0 |
| Extra CSV record | 1 | 0 |
| Too few CSV records | 0 | 0 |
| CSV LF framing | 0 | 0 |
| Unterminated CSV quote | 0 | 0 |
| Empty CSV | 0 | 0 |
| Invalid canonical UTF-8 | 1 | 0 |
| Injected canonical semantic-open EIO | 1 | 0 |

The experiment copies only the baseline checker into this private review directory, rewrites its two imports to the unchanged real modules, exports real local bundles, and tracks real delegated opens/closes. It closes baseline leaks after observing them. No product or acceptance artifact was modified by the reviewer.

## Limits and concerns not judged

- Did not validate rebuilt archives, full clean-clone entry, either MoonBit toolchain, private CI, or designated counterexample acceptance; those remain separate parent work.
- Did not claim fault-tolerant error precedence when the OS-level `closeSync` itself throws. The new `finally` delegates to the existing generator cleanup, just as the existing NDJSON/input cleanup already does. The experiments verify semantic/encoding/open-I/O error preservation with normal descriptor closure; synthetic failing-close behavior and recovery policy are outside this bounded change.
- Descriptor tests temporarily patch process-global `fs.openSync`; these tests run sequentially in the current file and restore the original in `finally`. Enabling within-file concurrent tests in future would require isolating this observation mechanism, as would the existing swap test.
