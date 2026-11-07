# Current Node integration work — 2026-11-07

User explicitly chose standard Node package entry, TypeScript declarations and runnable examples while preserving accepted baseline. Worktree: /Users/henryz/Desktop/比赛/moonsav/.dev/integration-20261107/worktree ; branch feature/node-integration based on50104a8. Main implementation checkout, accepted5c1ff8d archives/freeze and untracked docs/acceptance/docs/submission are untouched.

Original designated CURRENT=PASSED for exact5c1ff8d artifacts, report docs/acceptance/2026-11-06-final/REPORT.md in original checkout. Snapshot/hash in evidence/node-integration-20261107/accepted-baseline.json. This supersedes “new candidate no verdict” only for that baseline; new integration bytes need new evidence and do not inherit exact-byte approval.

Implemented root re-export of SavError/inspectSav/readSav, main/types with the original Node resolver preserved; discriminated JSON declarations and dev-only TypeScript5.9.3; installed Node example for real missing counts. Four new package tests RED→GREEN, precision tests RED→GREEN, full142 Node tests pass locally. Package smoke passed with root API/example on Node-only PATH. No parser, date or data-conversion change.

Current work: independent review, clean committed full/oracle/package verification and private feature-branch CI. Do not copy dirty trial archives into accepted dist/freeze. Plan/spec in docs/superpowers. Public release, event submission and branch merge not performed. Existing private push/CI authorization persists.
