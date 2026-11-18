# MoonSav task state · 2026-11-17

Phase: ZSAV and matching integer/IEEE754 endian milestones locally developer-verified; full IBM26 compatibility remains incomplete/unaccepted.
Branch: implementation. Endian test base6654d47459ca12bf8eb07ff4fe4a2500dff07d15,dirty=true; resolve latest local feature commit with git rev-parse HEAD. Build fingerprint and commands: evidence/endian-20261117/summary.json.

Verified: Node159/159;core19/19 each JS/native/wasm-gc;29 expected corrupt-input rejections;15 endian pairs equal, same survey2orders×3storage modes. ReadStat28file passes+2explicit HIGHEST/LOWEST data semantics disagreements;PSPP14nonempty BE files pass. ZSAV regression retained. Installed offline API/CLI handles BE ZSAV; old bundles missing byte_order remain readable. Fresh reviewer noP0/P1/P2; independently ran focused6/6.

Implementation: MoonBit owns all format/bytecode/order/semantics;Node bounded zlib only. Dictionary.byte_order preserved, numeric hex canonical. IBM/VAX/arbitrary mixed float order unproven. Portable core needs caller inflater for ZSAV data. New remoteCI definitions unrun; old sealed archives and owner acceptance pointer unchanged. No public push/release/registration. Do not bulk-stage docs/acceptance or personal docs/submission.

Remaining: freeze IBM26 save-option/codepage/record inventory; remaining codecs and full dictionary semantics; password protection; IBM26 original producer/readback; full new archive and designated acceptance. User has no IBM; independent tools first. Keep ReadStat semantic and tiny-ZSAV-block disagreements explicit.

Next command: git status --short
Next action: compatibility stage3 encoding/dictionary inventory then implementation; docs/COMPATIBILITY_TARGET.md. Current report: docs/progress/ENDIAN-20261117.md. Reproduce: .dev/venv/bin/python tools/verify_endian.py --output evidence/endian-NEW (new directory).
