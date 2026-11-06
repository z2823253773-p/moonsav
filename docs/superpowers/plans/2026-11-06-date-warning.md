# Raw date/time warning classification repair

> Execute inline in existing sole-writer implementation checkout, then fresh whole-change review. User explicitly requested this bounded correction and README/handoff synchronization; private push/CI authorization persists. Acceptance-owned files remain read-only/untracked.

**Goal:** RawDateFormat follows GNU SAV format codes20–30 and38–41; numeric/currency31–37 never trigger it. Strict-mode decisions follow the corrected warning without changing data.
**Architecture:** One private MoonBit code classifier, applied to numeric variables' print OR write declaration, at most one warning per variable. Preserve raw formats/numeric bits/missing states and inherited bundle warnings. No automatic date conversion or new format support.
**Spec:** docs/acceptance/2026-11-06/REPORT.md and GNU Variable Record table https://www.gnu.org/software/pspp/pspp-dev/html_node/Variable-Record.html . GNU page search cache and locally retained official PSPP2.0.1 format.def agree; initial direct web open timed out.

- [x] Read complete designated report: PASSED_WITH_NOTES for exact e453463 archives, historical Oct24 CHANGES_REQUIRED superseded for those bytes only. Reproduce unchanged date-warning script RED on current tgz.
- [x] Add code-level all-byte print/write classification tests and CLI valid F/PCT/DOT/currency/date/time positive/negative, strict export precommit, default export/check inherited warnings and raw data preservation tests. Observe RED.
- [x] Correct classifier and run whole Node suite plus both source profiles/core backends; source review independently checks mapping and data/strict-mode invariants.
- [x] Update packaged README/CONTRACTS before source freeze: actual platform matrix, baseline technical acceptance/known P3 repair scope, source-consumer `_` environment workaround; no organizer/publication/human-trial claims.
- [ ] Freeze candidate, clean-clone full AC01–18/oracles, rebuild exact packages, replay both unchanged acceptance scripts, consume final archives, run new-SHA private CI.
- [ ] Preserve e453463 artifacts/history. Update current manifest/TASK_STATE/M4/M5/handoff with baseline approval versus new candidate evidence; final docs-only private push. No competition submission or public release.

Ledger2026-11-06: designated P3 archive script exit1 on accepted e453463, observations confirm both false positives and missed codes. New26 Node cases had12 expected failures; two core tests failed semantically (14 prior tests passed). Minimal exact code match + numeric print/write OR fixes them; both profiles138 Node and16 core each3 backend pass. README uses verified e453463 CI matrix/technical baseline plus latest-manifest links, avoiding a circular promise of a not-yet-created run. No arbitrary unknown format conversion or schema change.

Independent source review: no actionable findings.512 numeric code variants,15 string variants, mixed print/write, negative-zero/missing preservation, strict export precommit and inherited bundle warnings pass;31/31 task tests pass. Acceptance exact-byte approval remains scoped to baseline e453463.
