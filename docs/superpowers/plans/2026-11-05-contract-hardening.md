# MoonSav object and I/O contract hardening implementation plan

> **For agentic workers:** Use superpowers:executing-plans inline; one fresh-context whole-change review at the end. Existing PRD, designated review and the user's direct continuation authorize repair without another design-selection round.

**Goal:** Close F1–F5 against the actual archive and publish one source-backed object/input/output contract with tested invariants.
**Architecture:** Keep parsing/semantic validation in MoonBit; share name, nominal-width and resource rules between SAV and bundle. Node remains bounded filesystem/codec/process adapter. Keep acceptance-side evidence read-only.
**Tech Stack:** Node24.15.0/ICU78.2; pinned isolated Moon0.1.20261023/moonc0.10.17+d971670cd; Python3.12.13, ReadStat1.3.3, PSPP2.0.1. Existing old toolchain remains supported and unmodified.
**Spec:** docs/PRD.md, docs/acceptance/2026-10-24/REPORT.md, public src/pkg.generated.mbti and current JSON Schemas.

## Global constraints

- Continue in the dedicated implementation checkout, sole product writer; preserve untracked docs/acceptance and do not stage or change its reports/payloads.
- Private origin push/Actions authorization persists. No public release, registry publication or registration.
- Keep complete input bytes bounded; no new GUI/analysis/format features. Unknown schema/unsupported semantics fail explicitly.
- Preserve exact old artifacts in ignored dist/history before replacements; fresh archive counterexamples, full independent oracles and new-SHA CI are required.

## Review focus

- A zero-row export with invalid names must fail before creating a committed bundle, including NDJSON.
- Rehashed metadata must not bypass label-byte, decoded dictionary or association-entry budgets; equality must still pass.
- Missing/wrong typed nominal_case_size must fail, while -1/0, physical and limited-first-255 conventions remain valid and preserved.
- Encoding override must supersede unsupported declarations without deleting source declarations/warnings.
- Canonical numeric validation must reject redundant forms while preserving signed zero, subnormals and exponent round trips on declared backends.

## Tasks

- [x] Read designated review and reproduce F1–F5 against unchanged delivered tgz; retain .dev/contracts-20261105/archive-red and its nonzero result.
- [x] Add independent Node/MoonBit regression vectors for each finding, including limits equality/one-over, required metadata types and legal unknown/long widths. Observe RED before fixes.
- [x] Repair shared names/nominal width/encoding precedence and canonical decimal validation; test direct library paths, CLI, rehashed bundles and successful export self-check.
- [x] Repair shared dictionary resource charging. Check label/raw payload before base64 materialization/association copies, decoded budget before retention; keep SAV raw cursor budget in addition to semantic payload budgets.
- [x] Audit all known object fields against parser/schema/public API; close confirmed boundary gaps, then write docs/CONTRACTS.md with units/nullability/enums/ownership/mutability/callback/error/lifecycle/file-state contracts. Document serializer preconditions and parser-vs-filesystem trust boundaries explicitly.
- [x] Run whole Node suite, both source profiles/core backends and full AC01–18/oracles. Preserve failed attempts. Rebuild exact archives and replay the unchanged designated counterexample script; no expected-result edits.
- [x] Obtain independent end review, run private three-platform CI for frozen source, update current manifest/TASK_STATE/handoff/hashes, preserve CHANGES_REQUIRED history and request designated re-acceptance via handoff only.

## Ledger

2026-11-05: HEAD da4ddb59b030d1f72c1180d382a1526ec086f80b; only untracked docs/acceptance. All five designated findings reproduced on original tgz; original CI is historical evidence. Ruling: repair in existing dedicated implementation checkout instead of moving acceptance-owned files or creating another checkout; stage product/evidence paths explicitly. Ruling: this is a repair of already authorized contracts, so no new product-design approval is needed. No claim of full final acceptance will be made on behalf of the original chat.

2026-11-06: F1–F5 repaired with red/green evidence. Source object audit also fixed closed nested shapes, Node option snapshots, decoder identity, signed machine-code preservation, linear text framing, callback ownership and checker result snapshots. Independent reviewer found inherited/nonenumerable Node options and noncanonical effective encoding; both fixed with regressions. Old/new profiles each pass108 Node and14 core tests on JS/native/wasm-gc. New formatter Int32/UInt32 alias incompatibility was observed on old compiler, corrected with compatible aliases and old formatter; failed logs retained. Freeze source next; final archive/full suite/remote checks still required.

2026-11-06 final: clean source a3c4b22 full entry17pass+29bad; exact archives rebuilt and unchanged designated replay passes; fresh agent15-command exact archive consumption and source recheck pass; new-SHA remote42243643477 all four jobs pass. Current handoff/manifest/report evidence updated. Designated re-acceptance remains pending and was not self-granted.
