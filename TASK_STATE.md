# MoonSav current state — date warning repair2026-11-06

The original designated acceptance report docs/acceptance/2026-11-06/REPORT.md gives PASSED_WITH_NOTES for exact e453463 source/archives. It supersedes the Oct24 CHANGES_REQUIRED for those bytes, preserving the historical report. Baseline scope and report SHA are in evidence/date-warning-20261106/acceptance-baseline.json. This is product technical acceptance, not competition/organizer approval or external-human trial.

Current requested follow-up fixes the remaining P3 RawDateFormat misclassification using explicit GNU codes20–30,38–41. Numeric print OR write date/time declarations warn once per variable; PCT/DOT/currency31–37 do not. Raw numeric bits/missing/format definitions remain unchanged. Existing old bundles inherit recorded warnings; re-export from SAV corrects old warnings.

Both declared compiler/core pairs now pass138 Node +16 core per JS/native/wasm-gc. Added26 CLI cases and2 exhaustive code tests went RED→GREEN; original P3 script RED reproduced on prior tgz. README now lists actual cross-platform baseline and distinguishes exact technical approval from subsequent correction. Independent review underway. Source freeze, clean full/oracle run, rebuilt artifacts, both unchanged challenge scripts, new-SHA CI and technical freeze remain to complete. Root dist still holds accepted e453463 artifacts; do not apply baseline approval to future hashes automatically.

Plan: docs/superpowers/plans/2026-11-06-date-warning.md. Sole product writer, existing implementation checkout. docs/acceptance stays untouched/untracked; private push/Actions authorization persists. No public registry release or event submission.
