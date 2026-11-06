# Exact candidate archive consumption — 2026-11-06

**Result: passed.** Independent local macOS consumption of the exact frozen candidate archives completed. This is technical consumption evidence, not designated acceptance of the candidate.

| Archive | Bytes | SHA256 |
| --- | ---: | --- |
| moonsav-0.1.0.tgz | 311136 | 2d6396266353c5b5f429427a823ed358eebf2ae1403d6abaa36e8c0a9db29ee1 |
| moonsav-source-0.1.0.zip | 75195 | dc5d7e509582b687018cacaa066461a16ae23ab338065fdfa6a1668269098dff |

Hashes/sizes were checked before copying, copied bytes compared, and checked again after consumption. Installed JS/build metadata equal those exact archive members. No archive was rebuilt during this followup.

The tgz installed offline with scripts disabled and an initially absent npm cache into a fresh consumer. CLI installation and execution used a PATH containing only Node; MoonBit/Python were absent from that PATH. Version, inspect, validate, export into a new Chinese/spaced directory, and check-bundle all passed. The separately invoked installed Python standard-library consumer passed. Five rows were preserved; inspect correctly reported actual rows as unscanned.

Installed metadata reports clean source `5c1ff8dc7fa6ea8ea65b9849f5bb921db602856b`, dirty=false, source digest `be4b72b90a6bdc927b085da3e89e477ce239f45cb2fb388251d5b271d41def71`, moon0.1.20261023/moonc0.10.17+d971670cd, Node24.15.0/ICU78.2.

Independent replay against that installed runtime passed all 256 print and 256 write codes, fifteen string-variable date-code probes, four mixed print/write probes, and strict inspect/validate/export/check behavior. Expected codes were derived from retained official GNU format.def categories. All row structures preserved an independently injected negative zero and existing user/system missing values. A self-consistent historical false-positive bundle warning remained inherited and strict check returned 7. Strict warned exports left no output directory. The supplementary replay records all 22 nested CLI commands/results in `installed-probes-logged/cli-records.json`.

The exact source zip was extracted separately for each compiler/core pair. The packaged consumer ran JS/native/wasm-gc successfully under both moon0.1.20260713/moonc0.10.4+2cc641edf and moon0.1.20261023/moonc0.10.17+d971670cd. Each process used its explicit toolchain PATH with `_` removed, following the documented environment workaround. All command lines, working directories, PATHs, exits, stdout/stderr, and full version outputs are in `result.json` and numbered logs.

One supplementary command-logging harness attempt incorrectly reused prior output directories because its JSON-escaped Unicode path replacement failed; the product returned OutputExists and the harness exited 1. That failure is retained as record16 and its logs. The harness was corrected to a fresh isolated directory, then the complete installed-runtime replay passed as record17. Original first-use/source-consumption commands all passed; the failed harness attempt is not presented as a product pass.

Limits: local macOS only; source-consumer execution rather than a new full source suite; no remote CI check, designated acceptance, publication, organizer approval, or external human trial. Existing baseline approval remains bound to its earlier exact bytes. Product and acceptance-owned files were not modified or staged.
