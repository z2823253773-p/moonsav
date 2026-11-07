# Independent exact artifact consumption — passed

Fresh reviewer: Codex subagent /root/node_integration_review. This followup consumes the final exact archives, rather than repeating source review. Frozen candidate c89ce1aa9fdea8114fe0d8157ee4de043da66583, clean embedded build metadata and source tree digest9284c43f6b4fa169869e0a44128c0acc0b44b59aeb7b933fd7551b5a50e96caa all verified.

## Exact bytes

- moonsav-0.1.0.tgz:313794 bytes, SHA2569366c3d597d5c4b846d0caa6c3741a62186428187b0378b0f59c7b89d5b33b8e.
- moonsav-source-0.1.0.zip:76185 bytes, SHA256f92ef14cd516f171cd8680e2a2357258869648c2444fe96f7daccbb98c2a4aa5.

Hashes were checked before and after consumption. Archive inputs were not rebuilt or changed.

## Observed results

All22 subprocess commands exited0. Full command arguments, working directories, relevant environments and exits are in commands.json, source-commands.json and supplemental-commands.json, with separate stdout/stderr files per command.

Fresh npm installation used an empty cache, --offline --ignore-scripts, and PATH containing only a node symlink. Actual runtime is Node24.15.0 / ICU78.2 / Darwin arm64. Installed package has no node_modules runtime dependency directory.

Root ESM and CommonJS consumers passed. Only SavError/inspectSav/readSav are root values; legacy API identities match. Actual sample data, leading-zero string, user/system missing cells and SavError identity passed. Previously broken CommonJS aliases require('moonsav/schemas/metadata.schema') and require('moonsav/lib/moonsav') now pass against the exact installed tgz.

Actual installed declarations passed the strict NodeNext positive/negative consumer, exactOptionalPropertyTypes and noUncheckedIndexedAccess. The compiler was host development TypeScript5.9.3 invoked by absolute path, not an installed runtime dependency or an ambient module stub.

Installed read_sav.mjs passed both its default bundled sample and explicit Chinese/spaced input path, with5 rows,3 variables and expected per-column missing counts. Installed CLI --version/inspect/validate/export/check-bundle passed, exported bundle was independently consumed by the installed standard-library Python example (5 rows,13 present cells). Embedded build metadata was verified and recorded separately.

The exact source zip was extracted into two fresh directories and consumed locally through its shipped examples/consumer under both supported toolchain pairs:

- moon0.1.20260713 / moonc0.10.4+2cc641edf: JS, native and wasm-gc all passed.
- moon0.1.20261023 / moonc0.10.17+d971670cd: JS, native and wasm-gc all passed.

All six source consumer runs verified labels, unlabeled valid values, text IDs, missing filtering, retained rows, Stop and consumer failure behavior. Toolchain versions were recorded live; inherited underscore and MOON_HOME were removed from source consumer environments. New compiler deprecation warnings remain visible in stderr logs and did not fail consumption.

## Scope

No new actionable issue observed in this exact-archive followup. The earlier package exports compatibility finding is resolved in the consumed archive. This is independent consumption evidence, not a designated technical acceptance verdict. Full oracle suites, remote CI, public release and event submission are outside this followup. Wrote only under this exact-artifacts directory; no product, original accepted checkout or accepted artifact edits were performed.
