> Current2026-11-13: integrated into implementation and designated exact-artifact PASSED. See docs/ACCEPTANCE_STATUS.md. The following is the historical integration work record.

# Node integration completion — 2026-11-07

Source `c89ce1aa9fdea8114fe0d8157ee4de043da66583`, digest `9284c43f6b4fa169869e0a44128c0acc0b44b59aeb7b933fd7551b5a50e96caa`. User selected package import/types/examples; original v0.1 mandatory features already had designated PASSED for5c1ff8d. This is an additional integration candidate, not new SAV support.

A fresh offline install of the accepted tgz reproduced root import ERR_MODULE_NOT_FOUND while deep API import worked. New node/index.mjs re-exports only3 stable values; package main/types provide ESM/fixed-Node24 CJS and declaration discovery. No parser, missing/date/text conversion logic moved into JS. Existing deep paths and CLI/schemas/Python files remain accessible.

The .d.mts declarations mirror actual snapshots: dictionary actual_rows=null; declared rows nullable; Cell/Atom discriminants preserve numeric-system missing nulls and string bits nulls; optional error context may be null/undefined; codes stay open. Explicit undefined options still use defaults, measure/alignment retain closed supported enums, arrays remain mutable snapshots. TypeScript5.9.3 is development-only and not required to run the installed API/example.

Installed examples/read_sav.mjs uses root import and the core's missing classifications, emits only row/column/count summaries, supports bundled sample or explicit file, and fails visibly on absent input. Actual archive tests use empty-cache/offline install with PATH empty and explicit Node executable; strict NodeNext compilation resolves real installed declarations, with expected errors for bad calls and null misuse. No ambient fake module/path mapping is used.

Independent review found1 P2: an initially tried wildcard exports map disabled old CommonJS automatic.json/.js lookup. The report and baseline/candidate probe are retained; real installed regression confirmed failure for metadata.schema and lib/moonsav, then main/types-only repair passed. Root wrapper still limits values. No other actionable/deferred findings. Installed alias test and full suite are the fix evidence, not a rewritten review report.

Both toolchains142 Node +16 core per3 backend; clean full entry17pass+29bad; public65449 cells no unexplained ReadStat/PSPP difference. Both original date/F1–F5 challenge scripts pass against exact rebuilt tgz. New [CI42384344415](https://github.com/z2823253773-p/moonsav/actions/runs/42384344415) all4 jobs pass. Actual final archive consumption is independently repeated with22 successful commands, types/ESM/CJS/aliases/example/CLI/Python and six source consumers. Mac oracle and Windows target exclusions remain explicit; dev tools/cache reused, not an empty-machine setup claim.

Evidence under evidence/node-integration-20261107. Accepted original archives/seal remain unchanged. New hashes lack a separate designated verdict. Candidate is on private feature branch; no merge, public release, contest action or external-human feedback is implied.
