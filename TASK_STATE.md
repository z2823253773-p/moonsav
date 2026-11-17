# MoonSav task state · 2026-11-17

Phase: ZSAV milestone developer-verified locally; IBM SPSS26 full-compatibility endpoint remains incomplete and unaccepted.
Branch: implementation. Test base HEAD b3774372eef8447703d0f5231ca4301393d931ec, dirty=true; tested source fingerprint/build and exact commands: evidence/zsav-20261117/summary.json. Resolve latest local commit with git rev-parse HEAD.

Verified: Node152/152; core18/18 each JS/native/wasm-gc;29 expected corrupt-input rejections; installed offline API/CLI reads ZSAV; same3×6 survey equal across three storage forms;3000 producer long strings recovered. ReadStat5 fixture comparisons and PSPP5 comparisons pass; handcrafted13-byte-block vector remains a recorded ReadStat oracle disagreement, not a pass. Fresh reviewer: noP0/P1/P2. Synthetic fixtures reproducible by SHA.

Architecture: MoonBit owns FL3 directory/blocks/bytecode/semantics; Node built-in bounded zlib primitive only. Total inflation256MiB, block16MiB,65536blocks. Portable core needs caller inflater for data scans. Full local logs retained under evidence/zsav-20261117; compact tracked report docs/progress/ZSAV-20261117.md.

Remaining: freeze IBM26 records/codepages/save-option inventory; big-endian propagation; remaining codecs/dictionary semantics/password protection; IBM26 original producer/readback when legitimately available. User has no IBM; independent tools first. New remoteCI/full product archive/designated acceptance not run. Old c89ce1a PASSED applies only to frozen historical subset. No public push, release or organizer submission this stage. Do not bulk-stage owner-maintained docs/acceptance or personal docs/submission.

Next command: git status --short
Next action: follow docs/COMPATIBILITY_TARGET.md stage2 and prepare endian equivalence cases; preserve ZSAV regression and old evidence. Plan: docs/plans/2026-11-17-zsav.md. Reproduce ZSAV: .dev/venv/bin/python tools/verify_zsav.py --output evidence/zsav-NEW (NEW directory must not exist).
