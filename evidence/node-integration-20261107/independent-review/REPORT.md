# Independent Node integration review — 2026-11-07

Reviewer: fresh Codex subagent /root/node_integration_review. Review target: uncommitted feature/node-integration worktree, based on50104a8. Read complete new spec/plan, tracked diff, root wrapper, declarations, example and installed runtime/type consumer tests. Product files were not edited.

## Finding P2 — Wildcard exports breaks previously supported CommonJS subpath resolution

Location: package.json:41-47, the new exports map, particularly `"./*": "./*"`.

A Node package without exports uses CommonJS extension lookup for package subpaths. An exports target resolves exactly. Consequently the broad passthrough does not actually preserve every former import path: under fixed Node24.15.0, baseline `require('moonsav/schemas/metadata.schema')` loads the shipped JSON schema and `require('moonsav/lib/moonsav')` loads the shipped JS module; the candidate throws MODULE_NOT_FOUND for each. Explicit full filenames continue to work. This conflicts with the spec's backwards-compatibility promise for existing file imports and the README statement that other package file paths remain accessible.

Reproduced from two independent consumer package boundaries with node_modules/moonsav symlinks targeting the untouched baseline and current candidate. Each consumer has its own package.json to avoid package self-resolution masking the baseline. Results: compatibility-probe.json next to this report.

Suggested repair: omit exports and retain main/types plus the three-value index.mjs wrapper; this still provides the requested stable root API and declaration entry while retaining Node's legacy subpath resolver. Alternatively, preserve the former aliases explicitly and add real installed-package regression coverage. Verify root ESM/CJS and strict NodeNext types after any repair.

## Verification and other reviewed behavior

- Independently ran `node --test tests/package.test.mjs`: 4/4 passed on Node24.15.0 / ICU78.2. These cover actual offline npm archives, root ESM/CJS, exact old paths, strict NodeNext declarations and installed example.
- Independently probed actual fixture JSON against the new declaration branches:32 successful supported fixtures,11 correctly rejected fixtures,175 cells and45 atoms. Probe checked dictionary-only scope, null actual_rows, encoding/profile, compression, display enum values, numeric/string atoms, numeric system missing, string/numeric cell nullability and optional error context types. Evidence: fixture-type-probe.json.
- No additional actionable issues found in root export identity, stable-root value visibility, declaration discriminants/nullability, option defaults, synchronous error shapes, source digest inclusion of .mts, archive inclusion of declarations/example, dev-only TypeScript dependency or CI npm setup.
- `git diff --check` passed.

## Limits and declined scope

This is a source/integration review, not designated technical acceptance. Did not rerun full oracle/toolchain/three-platform CI or exact final committed archives, which remain later gates in the plan. Did not change or re-evaluate parser/data semantics, date conversion, core streaming behavior, public release, event submission or original accepted artifacts. Did not propose extra facade functions, runtime dependencies or broad generated SDK work.
