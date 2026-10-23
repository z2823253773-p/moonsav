# MoonSav current implementation state

Updated 2026-10-23 America/Phoenix. User authorization is recorded in docs/IMPLEMENTATION_HANDOFF.md and PRD r0.2. Work proceeds continuously; no renewed design approval needed.

- Branch: implementation. Initial doc baseline 7b93a36; use `git rev-parse HEAD` and `git status --short` for current exact state. Code checkpoint includes this state; never infer a clean state from this file alone.
- docs/PLAN.md written and implementation active. Product code and TASK_STATE have a single writer; acceptance chat 01a168c9-225e-74c2-9868-7ffce7a79cd7 owns docs/acceptance/.
- Actual: MoonBit byte library handles FL2 little-endian IEEE754, compression 0/1, core dictionary and long-string reconstruction/labels/missing. Node adapter only provides codec, filesystem and hashes. CLI inspect/validate/export/check-bundle exists, default canonical NDJSON + standard CSV, metadata/codebook/manifest.
- Current tests: AC01 minimal synthetic both modes; U1 MoonBit consumer; independent Python canonical/CSV consumer; 14 Node regression tests. Core JS/native/wasm-gc compilation/UTF8 tests are being completed, exact logs in evidence/. These are developer runs, not independent final acceptance.
- Public cache is ignored under .cache/. Two files full-read and ReadStat cell/dictionary comparison: 634x88 and 87x111, 65449 cells; source hashes in evidence/public*-readstat.json. One original trailing variable-label space is preserved, ReadStat trims it; normalized difference explained. No raw public data in package/repository. Potential identifier field flags are aggregate only.
- M1 gate incomplete until runnable PSPP independent family and remaining encoding profile tests. PSPP source build lives in .dev/, oracle Python 3.12 venv locked in requirements-dev.lock. Failed setup/build experiments retained there.
- M2/M3 underway. Outstanding: complete fail-closed/limits tests, full schemas, interrupted/concurrent file behavior, clean archive install, performance AC18, formal AC01–18 verify entry and independent review.
- M4/M5 not complete. No remote CI execution, push, release, Mooncakes publication, registration, November rules confirmation or organizer acceptance.
- Continue: inspect current .dev/pspp-*-rpath.log and build result; implement missing acceptance vectors and evidence runner. Reports in docs/progress/ record scoped facts and gaps.
