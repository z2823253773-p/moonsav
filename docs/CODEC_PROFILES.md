# Encoding profiles

Every field is decoded strictly after byte reconstruction. Supported names are UTF-8/UTF8/65001, Windows-874, Windows-1250 through Windows-1258, GBK/CP936/936, and GB18030/54936. A supported Windows code page also accepts its cpN and numeric aliases. Generic ASCII machine code 2 is not a reliable code page. Override takes precedence and produces EncodingOverride; otherwise record20 and a reliable machine code must agree.

- `utf-8/moonsav-1`: Unicode UTF-8 with malformed sequences rejected, BOM retained. A legitimate U+FFFD remains data. Default byte-core backend uses MoonBit core UTF8 decoder.
- Windows-874 and Windows-1250 through Windows-1258 use separate profiles. The new profiles use frozen CPython 3.12 strict byte maps. Undefined positions fail with InvalidEncoding. The adapter preserves the mapped Unicode sequence, including combining marks in Windows-1258. A supported numeric machine code can select the corresponding profile when record 20 is absent. Mapping provenance and notices are in [THIRD_PARTY](../THIRD_PARTY.md).
- `windows-1252/moonsav-1`: Microsoft CP1252 mapping. Undefined positions 81/8D/8F/90/9D fail, ISO-8859-1 is not an alias.
- `gbk/moonsav-1`: stable CP936/GBK mapping defined by [Unicode's Microsoft CP936 table](https://www.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WINDOWS/CP936.TXT), checked against Python 3.12 strict GBK. All 2-byte positions are table validated and Node decoding must agree. CP936 single-byte 80 Euro is a variant not implemented by this GBK profile; returns UnsupportedEncodingVariant. A3A0 is undefined in strict GBK, not silently converted to ideographic space.
- `gb18030/moonsav-1`: deliberately bounded stable intersection. Two-byte mapping must agree between Python 3.12 gb18030 and Node24.15/ICU78.2. Four-byte mapping must agree with [WHATWG range index](https://encoding.spec.whatwg.org/index-gb18030-ranges.txt) (source hash frozen in evidence/codec-primary.json), and reserved pointers are rejected. Disputed mappings such as A3A0, A8BC and four-byte revision exceptions return UnsupportedEncodingVariant. This profile does **not** claim all GB18030-2000/2005/2022 variants; a SAV declaration alone does not distinguish them. Common Chinese and supplementary-plane characters have positive SAV test vectors. No source bytes are used to excuse a wrong decoded text.

Runtime adapter contains the frozen CP936 table, independent Python two-byte mapping and primary four-byte ranges; it does not invoke Python or iconv. Version, ICU and profile must be reported separately from byte-core default UTF8 capability. A backend without an adapter explicitly rejects non-UTF8.

`string_matching_policy=source-bytes-space-padded-width-v1`: compare logical source bytes, padding shorter keys on the right with ASCII 20. No Unicode normalization or decoded-text trimming. Only a numeric cell can be system-missing. GNU PSPP 2.0.1 `src/data/missing-values.c` uses memcmp for fixed-width string missing values; its `value-labels.c` uses width-sensitive value keys. GNU developer manual variable and long-string missing records specify the 8-byte key and space-padding constraints. Node decoder non-injectivity does not define equality. Independent executable PSPP/ReadStat comparison remains a required gate, tracked in M1/M4.

Sources are development references, not copied parser implementation. CP936 table redistribution attribution is recorded in THIRD_PARTY. Current mapping ambiguity is an explicit supported-profile boundary; it must not be advertised as all SPSS Chinese encodings.

Validation update: `evidence/codec-oracles-v2/` contains executable ReadStat and GNU PSPP positive comparisons for the original four profiles. `evidence/codec-four-pspp/` validates U+10000 in a four-byte GB18030 sequence through PSPP and its GNU libiconv. The Mac ReadStat wheel links the system iconv, which rejects bytes90308130; `/usr/bin/iconv` reproduces that oracle limitation. This does not remove the four-byte fixture or widen the accepted profile. Its raw source bytes remain in `encoding-gb18030-four.sav`; the independently authored source text, Python decoding, primary ranges and PSPP agree. ReadStat on that particular supplementary-plane vector remains an explicit oracle limitation, not a false pass.

Resource update after independent review: associated label entries are conservatively charged4096 bytes each against the dictionary budget, before allocation. Default limit is16384 entries across association copies and extended tables. This prevents a1.6MB /100000-label input from creating huge object graphs or spending quadratic time. Duplicate comparison uses semantic keys in maps; numeric ±0 are equal label keys and string padding uses byte20.


## Local encoding example

```sh
moonsav inspect survey.sav --json
moonsav export survey.sav --out survey-bundle --encoding windows-1251 --json
moonsav check-bundle survey-bundle --json
```

Use the override only when the source encoding is known independently. The resulting metadata records the effective profile, the file declaration, and how the selection was made. Exports use UTF-8, while the NDJSON byte fields retain the original logical string bytes. Windows-1258 validation preserves the exact decoded sequence. In the recorded PSPP environment, its CP1258 conversion produced canonically equivalent NFC text on the Vietnamese test case. The verification report records that difference separately from exact comparisons.
