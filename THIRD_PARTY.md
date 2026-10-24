# Third-party code, mapping data and development tools

MoonSav project source is Apache-2.0 (LICENSE). Synthetic fixtures and invented source values are dedicated under CC0-1.0. Public SAV data are **not** in either distributable; attribution/license/source hashes are in fixtures/manifest.json, and downloaded caches remain ignored.

The precompiled CLI incorporates MoonBit core library routines (Apache-2.0; https://github.com/moonbitlang/core). It has no npm runtime dependencies and never invokes ReadStat, PSPP, Python or a network service.

`node/codec-data.json` includes data derived from the Unicode-hosted Microsoft CP936 table (table version2.01 dated2000-01-07; https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP936.TXT), covered by the Unicode data license in licenses/Unicode-LICENSE.txt; WHATWG Encoding's GB18030 range index (2024-09-18, license notices in licenses/WHATWG-Encoding-LICENSE.txt); and a Python3.12 gb18030 mapping audit (Python license in licenses/Python-3.12-LICENSE.txt). Source hashes and mapping differences are frozen in evidence/codec-primary.json. The licenses directory is included in the npm archive. Python is not needed at runtime. Profile boundaries and disputed mappings are explicit in docs/CODEC_PROFILES.md.

GNU PSPP2.0.1 (GPLv3+) and pyreadstat1.3.3/ReadStat (MIT-family tooling) are independent development oracles only. No PSPP implementation source is copied into product sources or distributed archives. ReadStat implementation was inspected as a format reference at commit4fbf1d8e516513dc06c7a73aab03b3daced87d4f; no ReadStat runtime or parser source is bundled. GNU system-file documentation was used to independently implement the format. Optional oracle dependencies live under .dev/ and are excluded.

The first Figshare survey (Yuanming GUO, DOI10.6084/m9.figshare.24792756.v1, CC-BY4.0) and second research dataset (Rosa Vilaseca et al., DOI10.6084/m9.figshare.12459449.v1, CC0) were tested locally in full. Evidence contains counts/hashes/differences, never individual row values. Screening flags are not a claim that public data are anonymized or safe to redistribute.
