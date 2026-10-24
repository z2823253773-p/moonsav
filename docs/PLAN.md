# MoonSav Implementation Plan

> **For agentic workers:** Execute inline using superpowers:executing-plans; the user already authorized direct execution. Track the steps below and retain failed runs. No further plan approval is needed.

**Goal:** Implement the authorized PRD r0.2 as a MoonBit SAV byte library and offline Node CLI, with reproducible compatibility and local install artifacts.

**Architecture:** MoonBit owns cursor/header, dictionary, physical/logical reconstruction, compression, missing/label semantics, export serialization and bundle structural checks. A Node adapter owns bounded file I/O, SHA256, codec implementation and process handling. Python/ReadStat and GNU PSPP are development oracles only.

**Tech Stack:** Existing moon 0.1.20260713 / moonc v0.10.4+2cc641edf; Node 24.15.0 / ICU 78.2. Python 3.12 isolated venv. Lock actual oracle and codec dependencies before use.

**Spec:** docs/PRD.md r0.2; docs/PRD_REVIEW.md; docs/IMPLEMENTATION_HANDOFF.md.

## Global Constraints

- Work only in this new standalone project; initialize Git here on `implementation`. No remote/push/publish/registration.
- FL2 little endian IEEE754 compression 0/1, 1–32767-byte strings, subtype 13/14/21/22, labels, both missing kinds and raw display/date metadata are required.
- Four explicit codec profiles; no guessing, lossy decoding or base64 used to excuse incorrect text. Resolve string matching from independent format evidence.
- Every complete bundle has canonical data.ndjson + metadata.json + codebook.md + manifest.json; default adds RFC4180 data.csv. No private CSV escapes.
- Fail closed on unsupported/damaged input. Exclusive output directory, INCOMPLETE and final commit point. CLI exits 0/2/3/4/5/6/7/70 as PRD.
- Bounds: input 256MiB; dictionary raw/decoded 64MiB each; logical vars 100000; physical slots 1000000; string width 32767; label 1MiB; extension 16MiB; row 8MiB; rows 1000000; collected cells 5000000/128MiB; all output 512MiB.
- Actual public compatibility requires full comparison of two independently sourced public files and PSPP family. Local evidence is distinct from CI definitions/remote runs and independent acceptance.

## Review Focus

1. Non-injective/mismatched GBK/GB18030 codec mappings: test byte-key label/missing relations and profile exceptions (T1/T2).
2. Very long strings use 252-byte segment semantics with 255/256 storage: test 255/256/504/505/32767 and multibyte boundaries (T2).
3. Compression EOF, no-ops and row-count mismatch: bounded decode and exact count at EOF, including zero/unknown cases (T2).
4. Checker must reject internally consistent-looking but semantically invalid values even after rehashing, CSV multiline and symlinks (T3).
5. Exclusive output and each interruption point: only removal of INCOMPLETE commits, strict warnings never commit (T3).

## File Map and Public Interfaces

- `src/model.mbt`, `cursor.mbt`, `dictionary.mbt`, `data.mbt`, `codec.mbt`, `bundle.mbt`, `json.mbt`: public `inspect_bytes(Bytes, Options)->Dictionary raise SavError`, `read_bytes->Dataset`, `scan_bytes` callbacks returning ScanControl; immutable Cell/Variable accessors and structured SavError. Decimal+hex NumericAtom and byte-preserving string cells.
- `src/moon.pkg.json`, `moon.mod.json`, `src/*_test.mbt`: cross-backend byte core and semantic tests.
- `cmd/bridge/main.mbt`: MoonBit JS bridge exposing byte core to Node adapter, never a SAV parser in JS.
- `node/codec.mjs`, `node/cli.mjs`, `node/io.mjs`: strict codec + platform adapters; `bin/moonsav.mjs` launcher.
- `tools/generate.py`, `verify.py`, `build.mjs`, `capture.py`: independent fixtures, AC01–18 evidence entry, packaging and run ledger.
- `tests/*.test.mjs`, `examples/consumer`, `examples/read_bundle.py`, `schemas/*.json`: task/failure contracts and consumers.
- `fixtures/manifest.json`, `docs/CODEC_PROFILES.md`, `THIRD_PARTY.md`, `toolchain.json`, `requirements-dev.lock`, `package-lock.json`: frozen provenance/environment.

## T1 / M1: Fixed environment and highest risk vertical slice

- [x] Initialize scoped Git and ignore .dev, public cache, generated builds and evidence payloads with identifiers; commit inherited documents without altering them.
- [x] Lock Python/ReadStat and obtain independently runnable PSPP. Capture versions, reference machine, source hashes and provenance. Freeze corpus categories before testing.
- [x] Write failing AC01 tests: two compression modes contain score [1,2,99,sysmis], labels, decimals, string IDs, blank/NA/backslash/multiline. Assert missing kinds, raw bits/width, dictionary references and retained rows, not just a row count.
- [x] Implement minimal MoonBit types/cursor/dictionary/compression/strict decoding and bridge. Run `moon test --target js` and `python tools/verify.py --case AC01 --output evidence/M1-ac01`; failures must be saved before green.
- [x] Resolve codec profiles against primary mapping/format evidence and PSPP/ReadStat; test A1A1/A3A0, illegal tails, real U+FFFD, 1252 control bytes and GB18030 four-byte sequences. Document variants explicitly.
- [x] Build U1 consumer in a separate directory using local library dependency; assert missing filtering, unlabeled legal values, safe retained rows, Stop and ConsumerFailed. Export initial canonical/CSV and run independent Python reader.
- [x] Capture M1 report and commit actual deliverable; continue immediately.

## T2 / M2: Complete core semantics and rejection contract

- [x] Add failing tests for AC04–07/09/10: all compression opcodes, nondefault bias, all string boundaries, long names, extended labels/missings, range sentinels, -0, dates/display, declarations, invalid lengths/indices/unknown records and each limit boundary.
- [x] Implement dictionary extension parsing/reconstruction and missing/label semantics; recognized uninterpreted records retain payload and warning; never skip unknown semantic records.
- [x] Implement options/limits/encoding precedence and exact error context. Validate formats and strict strings only after reconstruction. `inspect` must not claim data validation.
- [x] Run `moon test --target js`, `--target native`, `--target wasm-gc`; run focused independent oracles for all AC04–07/09/10 classes. Review actual failing samples and preserve them.
- [x] Record M2 report + commit.

## T3 / M3: Product API, CLI, bundle and consumers

- [x] Write failing task tests for inspect/validate/export/check-bundle, CLI channels/exits, full JSON, summary truncation, zero/single-column/multiline/NUL, wrong metadata, rehashed-invalid cells, limits, extra files and symlinks.
- [x] Implement MoonBit canonical/CSV/metadata/codebook serialization and bounded structural/semantic checker; Node adapter handles hashes and bounded files, not SAV semantics.
- [x] Implement exclusive output transaction and input change detection. Test concurrent same-path exports, before/after-commit interrupts, write failures and strict warnings; assert unchanged input SHA.
- [x] Add schemas and runnable Python/MoonBit consumers. Build precompiled JS npm archive and test clean offline install with Node only on PATH.
- [x] Run AC08/11/12/14–17 and record developer U1–U3 reproduction. Save M3 report + commit.

## T4 / M4: Compatibility, performance and independent review

- [x] Audit public source licenses and identifiers, cache outside distributable. Compare every row/variable/label/missing/format field in >=2 public actual files; preserve normalization explanations.
- [x] Run `python tools/verify.py --all --require-public --require-pspp --output evidence/acceptance-current` with no skip-as-pass. Timeout each corrupt process at 10 seconds.
- [x] Run seeded 10000x20 compressed/uncompressed validate/export/check three times; median <=30s and peak RSS <=512MiB; deterministic semantic hashes (AC18).
- [x] Obtain fresh independent review and clean-directory reproduction (the delegated acceptance chat is the designated reviewer; optional review subagent if applicable skill requires). Fix confirmed findings with regression tests and rerun affected/full gates.
- [x] Save M4 actual findings, failures and untested platforms + commit. Do not claim acceptance before reviewer evidence exists.

## T5 / M5: Reproducible local delivery

- [x] Finalize README/API/help/examples, Apache-2.0 LICENSE, third party provenance, frozen dependencies and compatibility matrix tied to actual runs.
- [x] Add pinned macOS/Linux/Windows CI definitions and core backend jobs; label remote CI unrun until evidence exists.
- [x] Rebuild package, inspect contents, install in clean directory and run first-use sample offline; hash final artifacts. Fresh checkout reruns the same entry.
- [x] Update TASK_STATE and M5 report with exact branch/SHA/dirty, commands/exits, hashes, failures/uncovered and copy-ready acceptance steps. Public release/registration remain separate and unexecuted.

Completed checkboxes below mean the authorized **local** deliverable and captured runs. They do not approve the PRD on behalf of the designated acceptance chat or establish unrun remote platforms. External gates remain explicit in TASK_STATE and M5.

## Execution Ledger

2026-10-23: Inspected inherited docs and applicable ancestor instructions; no AGENTS.md or Git exists. User authorization overrides stale design-pending lines and skill plan approval pause. New project directory is already isolated from neighboring projects; use it directly, no additional worktree required. Python default drift observed (3.14.6); use existing python3.12 for oracle venv. No tests or product baseline exists, so baseline is not a green test claim.

2026-10-23 hardening rulings: retain the stable intersection GB18030 profile and reject ambiguous revision mappings rather than guess; preserve supplementary-plane fixture and record Mac system-iconv oracle limitation separately. Charge associated dictionary labels4096 bytes each (default16384), after the independent reviewer proved a100000-label compact input caused quadratic work and excessive object growth. Preserve BOM consistently across adapters. Source archives use root-anchored legacy include rules because this pinned Moon release did not apply .moonignore as expected; actual archive member inspection is the gate. Python verification subprocesses omit only the invalid inherited `_` last-command environment variable after it made the Moon tool panic; no global environment setting was changed.

2026-10-23 final local run: product8ae93f2, evidence/final-20261023-01.17 supported passes + AC09 expected rejects; zero failures/unexpected/not-run local cases.48 Node tests and7 core tests per three backends pass. Independent final archive reproduction passed after a preserved reviewer harness correction. Final reports and exact artifact manifest are M4/M5/FINAL_HANDOFF; remote Linux/Windows and designated acceptance remain pending. Branch retained, no publication.
