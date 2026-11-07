# Node package integration completion

User chose “先完善集成和使用流程” on2026-11-07. The accepted v0.1 MoonBit/CLI scope is complete (designated CURRENT=PASSED for5c1ff8d exact archives). This work addresses a reproduced integration gap: offline installed package root import fails ERR_MODULE_NOT_FOUND; only internal-path import works. Preserve accepted archives and original checkout.

Approaches: documentation-only deep-path instructions leave root import/type assistance missing. A thin package root plus hand-checked declaration file exposes already-supported APIs with no parser change (selected implementation approach). A new facade/data-conversion API or generated schema-wide SDK would change semantics and is unnecessary.

Ship a root module exporting only SavError/inspectSav/readSav; package main/types preserve the legacy Node resolver; no exports map is introduced. Declare stable JSON return models, explicit nullability, discriminated cells/atoms, options and optional error context. Types do not promise memory freezing, date conversion, closed error codes or extra Node functions. Pin TypeScript5.9.3 as a development-only verifier; runtime stays dependency-free, synchronous Node24.15.0/ICU78.2.

Ship an installed-package example that reads SAV and reports per-column missing counts without printing individual values. It uses the root import and the core's existing missing classifications. Include a no-input synthetic first-use path and explicit input path, with normal failure handling. Document ESM usage, full read versus dictionary-only inspect and nullable/error narrowing.

Tests consume actual npm archives in fresh offline directories, check ESM/CJS root loading on fixed Node24, existing deep paths, error identity, only-three public root values, real sample rows/missing kinds, and installed example. TypeScript strict NodeNext compilation uses the real installed declarations with positive narrowing and expected errors; no fake ambient module or implementation-generated expectations. Package smoke and CI execute these consumer paths; full compatibility remains required for new bytes. No public registry/event submission or extension of SAV format scope.

Review correction: the initially tried wildcard exports map broke CommonJS automatic.json/.js extension lookup. Baseline versus candidate experiment and real installed regression confirmed this. Remove the map; retain main/types and the three-value root wrapper. Root ESM/CJS/types/example still pass and old extensionless subpaths are preserved.
