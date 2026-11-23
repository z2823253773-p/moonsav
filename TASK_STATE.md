# MoonSav task state · 2026-11-22

Phase: ZSAV, matching IEEE754 endianness and Windows-874 / Windows-1250 through 1258, and structured dictionary annotations are locally developer-verified. Full IBM 26 compatibility remains pending.
Branch: implementation. Endian test base6654d47459ca12bf8eb07ff4fe4a2500dff07d15,dirty=true; resolve latest local feature commit with git rev-parse HEAD. Build fingerprint and commands: evidence/endian-20261117/summary.json.

Verified: Node159/159;core19/19 each JS/native/wasm-gc;29 expected corrupt-input rejections;15 endian pairs equal, same survey2orders×3storage modes. ReadStat28file passes+2explicit HIGHEST/LOWEST data semantics disagreements;PSPP14nonempty BE files pass. ZSAV regression retained. Installed offline API/CLI handles BE ZSAV; old bundles missing byte_order remain readable. Fresh reviewer noP0/P1/P2; independently ran focused6/6.

Implementation: MoonBit owns all format/bytecode/order/semantics;Node bounded zlib only. Dictionary.byte_order preserved, numeric hex canonical. IBM/VAX/arbitrary mixed float order unproven. Portable core needs caller inflater for ZSAV data. New remoteCI definitions unrun; old sealed archives and owner acceptance pointer unchanged. Check the public ref and its Actions result separately from local evidence. Do not bulk-stage docs/acceptance or personal docs/submission.

Remaining: freeze IBM26 save-option/codepage/record inventory; remaining codecs and annotation variants; password protection; IBM26 original producer/readback; full new archive and designated acceptance. User has no IBM; independent tools first. Keep ReadStat semantic and tiny-ZSAV-block disagreements explicit.

Next command: git status --short
Next action: extend encoding checks to East Asian and ISO profiles, then verify additional IBM 26 dictionary variants and password protection. Scope: docs/COMPATIBILITY_TARGET.md.

Latest evidence: Node 163/163 and 19/19 on each MoonBit core backend. Nine UTF-8/local-code-page pairs, 18 ReadStat comparisons and 17 exact PSPP comparisons. The remaining PSPP comparison is a documented Windows-1258 NFC disagreement. See docs/progress/WINDOWS-CODEPAGES-20261122.md and evidence/windows-codepages-20261122/summary.json. Reproduce with .dev/venv/bin/python tools/verify_windows_codepages.py --output evidence/windows-NEW. Logs are in .dev/windows-codepages-20261122.

Dictionary annotations: Node 168/168, core 19/19 per backend. PSPP reopens the generated file and displays the same documents, attributes and response-set label. Three fixtures pass ReadStat with a separate source-byte audit. Details in docs/progress/DICTIONARY-ANNOTATIONS-20261122.md and evidence/dictionary-annotations-20261122/summary.json.
