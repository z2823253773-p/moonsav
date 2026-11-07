# Node integration implementation plan

> Execute inline using executing-plans, then one fresh whole-change reviewer. User explicitly selected this scope; technical choices follow the spec. Preserve accepted source/artifacts and untracked acceptance/submission materials in original checkout.

**Goal:** Standard Node package import, accurate TS types and runnable installed-package integration example.
**Architecture:** Thin root re-export of existing API, declarations for existing JSON models, examples consume core classifications. No MoonBit parsing/data change.
**Spec:** docs/superpowers/specs/2026-11-07-node-integration.md; original docs/CONTRACTS.md stable Node API.

## Files

Create node/index.mjs, node/api.d.mts, examples/read_sav.mjs, tests/package.test.mjs, tests/types/consumer.mts. Modify package.json/package-lock.json, README, CONTRACTS, tools/package_smoke.py and CI consumer test/dependency setup. Add current coverage/status report with verified baseline. Evidence under evidence/node-integration-20261107, payloads ignored.

## Gates

- [x] Verify accepted archive hashes and baseline138 tests. Reproduce installed root import failure vs working deep import.
- [x] Add runtime installed-package tests and positive/negative strict TS consumers; observe RED before root/type/example implementation.
- [x] Implement wrapper, precise discriminated JSON declarations and example. Preserve old resolver behavior with main/types and no exports map. TypeScript dev-only pinned5.9.3.
- [x] Run focused then full Node suite; package smoke validates root API/example with Node-only runtime. Update public docs and current function coverage.
- [x] Independent fresh source review; fix confirmed findings using RED→GREEN. Preserve failed commands and reviewer identity/limits.
- [x] Commit candidate, clean-clone full/oracle/old+new toolchain/actual archive tests; private branch CI all platforms. Original accepted archive remains untouched.
- [x] Record exact new artifacts/source/test/CI, old accepted baseline versus new candidate scope, branch/worktree/handoff. Push private feature branch; no merge or public release.

Review focus: nullable system-missing fields must narrow safely; explicit undefined options remain valid; root cannot leak internal bridges; installed types must resolve without source path mappings; deep imports and CLI/Python samples must remain accessible.

Ledger: Native worktree RPC failed to return after repeated waits and was terminated; list_artifacts and git worktree list confirmed none created. Manual fallback created ignored .dev/integration-20261107/worktree on feature/node-integration at50104a8, preserving implementation and its untracked docs/acceptance/docs/submission. Baseline138/138 passed. Existing private push/CI authorization applies; merge/publication remain outside scope.

Ledger2026-11-07: four actual npm-consumer tests all RED before implementation, then4/4 and whole142/142 passed. Installed strict NodeNext fixture contains real nullable narrowing and expected invalid-call errors; measure/alignment union precision separately went RED→GREEN. Source digest scan now includes.mts declarations. No new SAV or core semantics. Exports map retains broad subpath passthrough to preserve pre-existing package file paths; root only exports three stable API values. npm pack/Node-only API/example/Python/source smoke passed.

Final review finding P2: wildcard exports broke legacy CommonJS extension lookup for metadata.schema and lib/moonsav. Real installed regression observed RED, then main/types-only repair preserves both aliases while root wrapper limits values. No new parser behavior. This corrects the earlier passthrough design; review had no other actionable finding or deferred minor. Original source/acceptance/freeze remain untouched.

Post-review final local profiles verified: old moon0.1.20260713 and new0.1.20261023, each142 Node and16 per3 core backend. Compatibility repair4/4 package tests and Node-only package smoke pass. No deferred findings. Candidate source freeze next; native original accepted branch/files remain untouched.

Final candidatec89ce1a: clean full17pass+29bad,142 Node and16 each backend, exact archives independently22 commands pass, newCI42384344415 all4 success. Original accepted branch/archive/report untouched. New integration candidate remains separate; final status/evidence report-only commit and private draft PR follow. No branch merge or publication.
