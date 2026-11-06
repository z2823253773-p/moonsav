# Independent contract recheck

Reviewed source: a3c4b225008c9af2c4fac3d60a63339ada8c19c7.

Both previously reported findings are closed in this source and the locally built CLI/API:

- Node stable API: node/api.mjs lines 21-46 now checks ordinary data objects and their own descriptors, rejects custom prototypes/proxies/accessors/symbol keys, validates nonenumerable data fields, and passes a null-prototype snapshot to dispatch. Replayed all six previous failing API calls: each now throws SavError with Usage.
- Serialized effective encoding: src/bundle.mbt lines 347-353 now requires the original token to equal its canonical value. Replayed the two previously accepted rehashed bundles with UTF-8/utf8 tokens: each now exits 4 with IntegrityMismatch.

Targeted checked-in regression run: node --test --test-name-pattern='serialized effective encoding|Node byte options are validated' tests/contracts.test.mjs. Result: 4 passed, 0 failed. Additional replay output: recheck-a3c4b22.json.

Reviewed updated public Node contract text and relevant whole-change source against the earlier F1-F5 report. No remaining actionable finding was confirmed in this recheck. Product/schema/test/docs diff whitespace check passed. No product or acceptance files were edited. Only experiments and this report were written under .dev/reviewer-contracts-20261105.

Scope: independent contract/source recheck with targeted local execution. This is not designated final acceptance, a fresh-archive/full-oracle run, or proof of new remote CI. Parent is performing those separately.

## Exact archive consumption completed

Independently checked the parent-provided exact archive hashes, then installed and consumed them in fresh Chinese/space paths under the permitted reviewer directory. CLI archive SHA256: 3be70b3312b6f632d1c03a2aea5106255ed3f71c6a2260666191b70e9371dea0. Source ZIP SHA256: 958968861f79eb08eaaed87368f117bfb95e94420f780ea9a20c3ac283b49517.

15 commands all exited 0: npm offline installation with local package.json/prefix/cache and Node-only PATH; version, inspect, validate, export, check-bundle, installed Python standard-library consumer; toolchain versions and extracted-source consumer JS/native/wasm-gc for both pinned profiles. Node output confirms clean a3c4b22 build; all full-file commands and Python consumer confirm 5 rows. The two source consumers were extracted separately from the exact ZIP, without root-source substitution. Commands, exits, exact hashes, build information and stdout/stderr logs are in `精确归档 fresh consumer/result.json` and its numbered logs. Reproduction helper: consume_exact.py.

This expands the evidence to independent exact-archive consumption; it still is not designated final acceptance or new remote CI.
