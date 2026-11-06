# MoonSav current state — 2026-11-06

Contract repair source `a3c4b225008c9af2c4fac3d60a63339ada8c19c7`; branch implementation; private repository https://github.com/z2823253773-p/moonsav . Current report HEAD/upstream/status are checked live in ignored dist/delivery-state.json. Later report commits do not change frozen product files.

All supported public models, entry points and I/O are specified in docs/CONTRACTS.md, including units/defaults/nullability/ownership/error/state boundaries and serializer preconditions. Designated findings F1–F5 are repaired, with unchanged final-archive counterexamples now all meeting expectations (exit0); old RED remains retained. Additional object audit and independent review fixes are recorded in docs/progress/CONTRACT_HARDENING.md.

- Both fixed toolchains:108 Node tests and14 core tests each JS/native/wasm-gc passed locally. New formatter alias incompatibility was observed, corrected and retested on both; default toolchain was not replaced.
- Fresh committed clone full AC01–18:17 supported_pass + AC09 expected_rejection29 vectors; no failures/unexpected/not_run. ReadStat/PSPP public-file comparisons cover65449 cells with no unexplained differences. Actual dependencies/tool/cache reuse and Mac oracle limitation are retained in raw results.
- New run42243643477 SUCCESS: Windows2025, Ubuntu24.04, macOS15 and independent Linux oracle jobs. Windows97 shared tests and14 core each JS/wasm-gc; Linux/macOS108 Node and14 each JS/native/wasm-gc. No Windows native/POSIX claim. Workflow URL: https://github.com/z2823253773-p/moonsav/actions/runs/42243643477 . Raw state/logs and downloaded summaries: evidence/contracts-20261105/remote-ci.
- Exact local tgz/source zip rebuilt from clean source; digest `7e73f6a651c53450b84a93a0c65815e91829112fbcb4dea25a0989e3ff6b2ace`. Both contain docs/CONTRACTS.md. Independent reviewer consumed exact hashes:15 commands exit0, offline Node plus Python and two-toolchain/three-backend source consumers. Earlier archives retained under dist/history.
- Source review found no remaining actionable issue in its scope. It is an agent review, not designated final acceptance. Original designated verdict remains CHANGES_REQUIRED pending re-acceptance on the new candidate; docs/acceptance was not edited or staged. Tracked product clean is distinct from these acceptance-owned untracked files.

Read docs/FINAL_HANDOFF.md and docs/delivery-manifest.json for exact archives and re-acceptance. Public npm/Mooncakes release, competition registration, organizer approval and external-human trial have not been performed.
