# MoonSav current acceptance — 2026-11-13

The Node integration candidate has completed designated technical reacceptance and is integrated into `implementation`. This extends the accepted 5c1ff8d baseline with standard package-root imports, precise TypeScript declarations and an installed Node consumption example. No new SAV format or conversion policy is introduced.

Frozen product source: `c89ce1aa9fdea8114fe0d8157ee4de043da66583`. Reporting tip before this status update: `8ac5e9d6998346097029acdf66a3d3d10bcb4049`. Later status documentation is separate from the immutable package snapshot.

| Exact artifact | Bytes | SHA256 |
| --- | ---: | --- |
| moonsav-0.1.0.tgz | 313794 | `9366c3d597d5c4b846d0caa6c3741a62186428187b0378b0f59c7b89d5b33b8e` |
| moonsav-source-0.1.0.zip | 76185 | `f92ef14cd516f171cd8680e2a2357258869648c2444fe96f7daccbb98c2a4aa5` |

Local sealed delivery: `dist/submission/moonsav-0.1.0-20261113-c89ce1a`. Archives are copied from the verified clean build, not rebuilt from a documentation-only commit. Earlier sealed archives remain unchanged. `dist` is Git-ignored: source-clone users build the package following README, or obtain the stated archives from the project owner. No public registry release is claimed.

## Fresh verification

- Full compatibility entry in a separate clone: AC01–AC17 passed with the expected corrupt-input category; 29 rejection vectors behaved as required. Node suite:142/142. Modern-toolchain core:16/16 each JS/native/wasm-gc.
- AC18 was separately repeated successfully after allowing host resource measurement. `/usr/bin/time -l` initially exited1 because sandbox sysctl access was denied even though product commands succeeded. The same seeded10000×20 benchmark, all18 runs, budgets and semantic-hash checks were retained; no performance expectation was weakened.
- The first Node package run hit sandbox EPERM writing the global npm cache. The next run used only a per-process project-local cache and passed. Original failure evidence is preserved locally.
- Exact archives:19 top-level consumer/challenge commands all exit0, including offline empty-cache npm installation, Node-only CLI, root ESM/CommonJS, legacy aliases, real strict NodeNext declarations, installed Node/Python examples, two fixed toolchains×three MoonBit source consumers, original F1–F5 and date-warning challenge scripts.
- Independent fresh-context source review confirmed both archive hashes/sizes, all27 tracked npm members and all32 source ZIP files match product-source Git blobs; no P0/P1/P2 finding.
- [CI42384344415](https://github.com/z2823253773-p/moonsav/actions/runs/42384344415) was read live and is completed/success at the exact frozen product SHA, with all4 jobs successful. Local exact bytes were consumed on macOS; runner-built archives are not asserted byte-identical.
- Post-integration checks additionally run the Node suite and baseline-toolchain core tests. See the retained acceptance report for actual results.

Compact machine-readable evidence is in `evidence/reacceptance-20261113/summary.json`. Full local logs, review, exact commands, failed attempts and original challenge outputs are retained under `docs/acceptance/2026-11-13-integration/`; this owner-maintained directory is intentionally not bulk-published. Existing tracked integration evidence remains under `evidence/node-integration-20261107/`.

## Reproduce from source

Use Node24.15.0/ICU78.2 and one complete toolchain pair in toolchain.json. Install the locked TypeScript development dependency with `npm ci --ignore-scripts`; runtime API/CLI has no npm dependencies. Use platform-native Python/PSPP tooling and requirements-dev.lock for the full comparison suite.

```sh
node tools/build.mjs
npm test
moon test src --target js
moon test src --target native
moon test src --target wasm-gc
python tools/verify.py --all --require-public --require-pspp --output .cache/verify-new
```

Output must be a fresh path. Under a restricted sandbox, choose a writable process-local `npm_config_cache` and allow actual host resource measurement for AC18. Do not count setup restrictions as parser failures or suppress missing measurements. Original fixed-toolchain consumer may require removing malformed environment variable `_` for that process.

## Review notes and boundaries

One nonblocking test-quality note is deferred: three `import.meta.resolve` checks in tests/package.test.mjs prove URL resolution, not file existence by themselves. The exact archive member audit and broader consumption checks verify the actual files. Current README/public-repository status has been synchronized; the historical frozen package README is retained as part of its exact bytes.

This is product technical acceptance within the documented format/encoding/size/platform limits. The default byte core remains UTF8-only without a trusted Decoder. Windows native/POSIX equivalence, all GB18030 revisions, new SPSS formats, automatic date conversion, external-human trials, registry publication and competition approval are not established.

The repository is public. Integrating an existing feature does not prove the competition's “at least10 effective commits” condition: raw commits, substantive code changes and documentation/evidence remain separately counted. No commit splitting, empty commits or retroactive history fabrication was used.
