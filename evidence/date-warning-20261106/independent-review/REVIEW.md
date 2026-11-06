# Independent date-warning repair review — 2026-11-06

Assessment: **No actionable findings in the reviewed change.** This is a source-change review with independent local experiments, not designated product acceptance or approval of a new release archive.

## Reviewed scope

Working-tree diff against HEAD `74216e57cabf3e439fdb10f364d7e1c7f0a3043b`: `src/dictionary.mbt`, `src/semantic_test.mbt`, `tests/tasks.test.mjs`, `README.md`, `docs/CONTRACTS.md`; plus the untracked implementation plan `docs/superpowers/plans/2026-11-06-date-warning.md`. Snapshot diff and SHA256 values are retained alongside this report. No product, tracked test, acceptance, or staging changes were made by the reviewer.

Read `docs/acceptance/2026-11-06/REPORT.md` in full, without altering or staging it or any other acceptance-owned file. The report establishes `PASSED_WITH_NOTES` only for the specified `e453463` source and exact archive hashes. README explicitly preserves that limitation for rebuilt candidates and separates technical acceptance from organizer acceptance, publication, and human trials.

## Findings and independent evidence

- The private classifier's fifteen codes exactly equal the date, time, and date-component entries in retained official GNU PSPP 2.0.1 `src/data/format.def`: 20–30 and 38–41. PCT/DOT/currency 31–37 are excluded. It checks numeric variables' print OR write format once, so a variable with two date formats gets one warning. No conversion, new parser format support, or data-path change was introduced.
- Independent `probe.mjs` derives its expected set from the GNU file's category declarations rather than copying the product classifier. All 256 print codes plus all 256 write codes passed. Fifteen string-variable declarations with date-format codes did not create numeric-date warnings; four mixed-format variants gave the expected count.
- Those 527 numeric/string variants preserved the entire canonical row structure against the same unmodified-format input, including an independently injected IEEE754 negative zero (`8000000000000000`) and existing user/system missing values. The original file's dictionary terminator/data offset was checked before injecting the value.
- Independent strict CLI probes covered PCT/CCE, write-only MTIME, print-only YMDHMS, and two date declarations together: inspect/validate strict exits, ordinary export/check, inherited warnings, and strict export with no output directory on rejection all matched requirements. A historical false-positive RawDateFormat was added to a self-consistent PCT/CCE bundle with its metadata size/hash updated: ordinary check retained the warning; strict check returned 7. This corroborates the documented “re-export from SAV to correct old warnings” behavior.
- The changed task test file passed 31/31 on the current generated modern-toolchain JS library. `git diff --check` passed. The generated build metadata reports Node24.15.0/ICU78.2 and moon0.1.20261023/moonc0.10.17+d971670cd; its dirty-source digest is recorded in `results.json`.
- README's CI runner/target descriptions agree with the committed workflow. Its fixed baseline SHA, four-job CI success, local-versus-runner archive distinction, known oracle limits, source-consumer environment workaround, and historical-versus-current acceptance language agree with the designated report. CONTRACTS accurately states numeric-only, print/write union, one warning per variable, strict rejection, raw preservation, and warning inheritance.

## Limits

This review did not run independent native/wasm-gc or old-toolchain builds, the full AC01–AC18/public-file/oracle suite, remote CI, new archive consumption, or the unchanged acceptance scripts. The implementation parent's runs remain separate evidence. The generated library was consumed without rebuilding it so this review did not interfere with the sole writer's build state; reviewed source hashes and library hash are retained. Later source/docs modifications require their own check against this reviewed snapshot.

The handoff/manifest/final candidate freeze work is outside this bounded source review and was not in its initial reviewed diff. The parent reports completing both exact toolchain pairs (138 Node tests and 16 core tests per JS/native/wasm-gc backend); those runs were not repeated by this reviewer. New source/archive hashes and new-SHA CI results must remain synchronized before delivery. No new exact-byte archive has designated acceptance from this review, and the old approval cannot be transferred to it.

Evidence: `reviewed.diff`, `reviewed-sha256.txt`, `tasks.log`, `probe.mjs`, `results.json`, and generated probe inputs/bundles in this directory.
