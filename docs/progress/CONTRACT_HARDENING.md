# Object and I/O contract repair — 2026-11-06

Frozen product source: `a3c4b225008c9af2c4fac3d60a63339ada8c19c7`. Source digest: `7e73f6a651c53450b84a93a0c65815e91829112fbcb4dea25a0989e3ff6b2ace`.

The designated archive review returned CHANGES_REQUIRED on the previous delivery. Its files remain read-only. This repair preserves that history and supplies a new candidate for re-acceptance; it does not issue the designated approval itself.

## Contract changes and evidence

| Finding | Resulting behavior | Boundary proof |
| --- | --- | --- |
| F1 zero-row NUL long name | Shared dictionary validation rejects before export directory creation, CSV and NDJSON | zero-row regression and unchanged final-archive replay |
| F2 label budgets | Shared raw/decoded/association counters; label length checked before base64 decode/copies | 16383/16384/16385/17000 entries, 1MiB/one-over, cross-variable cumulative counters |
| F3 nominal_case_size ignored | Required signed field read, preserved and checked | missing/type/null/fraction/wrong widths reject; -1/0, physical and limited-first-255 widths pass |
| F4 encoding override precedence | Explicit valid override chosen before unsupported declaration validation | UTF-7 declaration plus UTF-8 override succeeds, original declaration/warning preserved and bundle self-check passes |
| F5 noncanonical decimal | Decimal must match finite IEEE bits and canonical shortest formatter | redundant forms reject; -0, exponents, min subnormal and max finite pass on all declared backends |

The whole-object audit also closes nested schema objects, validates Node byte API argument/option types and snapshots own properties, preserves signed source machine code, requires usable decoder identity, rejects noncanonical serialized effective encoding, aligns metadata/record framing with total output budget and makes framing linear. Callback dictionaries and checker returned counters are independent snapshots. `docs/CONTRACTS.md` lists every supported public object, field/default/unit/nullability, public entry, helper precondition, error, file, state and trust boundary. Both actual archives contain it. Unknown metadata/variable/manifest annotation fields remain explicitly nonsemantic; this is not a claim to authenticate the original SAV or codebook semantics by hashes.

## Local verified candidate

- Both declared compiler/core pairs:108/108 Node tests;14/14 MoonBit core tests on each JS/native/wasm-gc.
- Fresh committed clone full entry:17 supported_pass, AC09 expected_rejection with29 vectors, no failures/unexpected/not_run. Fixed development tools and SHA-checked public cache reused; no empty-machine dependency setup claim.
- Two public files:634×88 and87×111,65449 cells compared with ReadStat/PSPP, no unexplained differences. Existing trailing-space normalizations and Mac ReadStat supplementary-plane limitation remain recorded in original results.
- Exact npm archive installed offline with only Node on PATH, empty npm cache; version/inspect/validate/export/check and Python standard-library consumer passed. Exact source archive consumer passed JS/native/wasm-gc. Schema checks and performance task passed.
- Unchanged designated `reproduce_findings.py` executed against the rebuilt tgz: all expectations met, exit0. Original archive RED exit1 is retained separately.
- Python development harness unittest:1 passed.

Evidence: `evidence/contracts-20261105/`. `full-run/summary.json` is the raw local result; its not_run cross-platform notes are local scope, not workflow conclusions. `full-entry-command.json` records interpreter/tool paths and reuse. No raw public data or acceptance-side payloads were copied.

## Review and compatibility corrections

A fresh independent agent found two extra gaps: inherited/nonenumerable Node options bypassed validation, and effective encoding aliases were normalized despite the schema enum. Both now have regressions. The reviewer is a code reviewer, not the original designated acceptance authority.

A newer formatter introduced Int32/UInt32 aliases unsupported by the old pinned compiler. That actual failure is retained as old-native.log; compatible Int/UInt aliases and the old formatter restored both profiles. An intermediate test wrongly expected dictionary-only inspect to enforce the scan row limit; the test was corrected to distinguish inspect from read. Failed attempts are not counted as passes. Raw compiler logs retain warning whitespace intentionally.

## Remote and delivery binding

Private run42243643477 is bound to a3c4b22. Final workflow conclusion, exact artifact hashes and independent archive consumption are recorded in the updated delivery manifest and M4/M5 after live verification. Earlier40073319985 remains historical evidence for the superseded candidate.

No public registry release, competition registration, organizer approval or external-human trial was performed. The original designated acceptance chat must independently reassess the new exact archives.
