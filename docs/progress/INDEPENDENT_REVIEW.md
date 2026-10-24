# Independent agent review

Reviewer: fresh-context agent `core_review`; read-only scope, experiments only under .dev/reviewer. This is agent review, not external-user feedback or designated acceptance-chat approval. Base7b93a36; initial product checkpoint8d0319a and subsequent working tree.

Confirmed findings and actual responses:

- Semantic duplicate labels (+0/-0 and padded string keys) silently selected a first label. Added failing repros, shared semantic-key invariant and map-based rejection; source and checker reject conflicting definitions.
- Rehashed bundle metadata allowed duplicate labels, invalid weight references, discrete endpoint tags and impossible slot layouts. Added failing tests and shared shape/reference/physical-layout checks.
- An empty dictionary could fabricate one case and export a bundle that its own checker rejected. Empty logical dictionaries now fail InvalidDictionary before encoding/data processing.
- Checker originally hashed one open and parsed a later open. A deterministic replacement could pass. It now hashes the exact NDJSON/CSV bytes consumed by semantic parsing and separately binds metadata bytes; the second-open swap regression rejects.
-100000 labels in1.6MB caused quadratic work and exceeded10s. Removed quadratic comparisons and added documented preallocation label-bookkeeping budget; repro now rejects ResourceLimit promptly.
- Ordinary string widths bypassed Options.string_bytes. Shared logical-variable validation now applies the limit to all string widths, not only subtype14.
- Default core UTF8 decoder dropped a leading BOM, unlike Node adapter. Regression first failed; ignore_bom=false now preserves U+FEFF on JS/native and matches Node.
- Malformed bundle UTF8 was classified Io/exit3. Platform text readers now map it to InvalidEncoding or framing IntegrityMismatch/exit4. All four bundle text positions have regressions.

Reviewer re-ran the earlier concrete reproductions and confirmed the label, metadata, empty-dictionary, race, width, large-label and BOM responses. The last reviewer message reported only malformed UTF8 (P2) remaining; the subsequent red/green record is evidence/review-bundle-utf8-{red,green}.log. No important/critical findings remained within its stated scope. Later changes added decoder identity and explicit CSV/encoding/uninterpreted-metadata policy validation; those have separate red/green tests in evidence/metadata-policy-{red,green}.log.

Root verification: evidence/review-regressions-*, review-race-green.log, review-bom-*, review-bundle-utf8-*, metadata-policy-*. These logs retain failed attempts. Source package and clean consumer re-review is a separate delivery check, not assumed from this review.

## Final artifact reproduction

At product SHA8ae93f2b46ab7a81acbf7a120564c493693324fb, the reviewer independently installed the unchanged final npm archive offline with only Node on PATH and extracted the source ZIP into a new consumer directory. Version/inspect/validate/export/check-bundle, isolated Python standard-library reader (5 rows,13 present cells), and source U1 on JS/native/wasm-gc all exited0. It verified source bytes against the reviewed implementation and checked no hidden development imports/payloads. Installed-artifact malformed UTF8 cases exited4; rehashed invalid CSV, encoding selection and unknown-extension policies rejected as expected. No remaining concrete issue was found within this delivery scope.

Exact commands/expected and actual exits/logs/member lists/unchanged hashes are in evidence/independent-artifact-final/run-02/report.json. npm SHA25626e79e5f6974551bcbea967090992ad771c91e363f3b30b7e53f0e2f24bfad3e; source6137341fc0be5e17d7a15bb4f571b9e726e582ba19a02df4f22ecb2411c53cce.

The first reviewer harness attempt ran npm install from an empty nested directory, which selected the parent project and added an accidental self-dependency. That harness failed; exact accidental diff, command and restoration are preserved in run-01/report.json. package.json/package-lock.json were restored byte-for-byte to reviewed HEAD and the created node_modules moved into ignored reviewer scratch. The corrected run used an explicit prefix and local package.json. Parent independently confirmed no package-file diff. Neither failed harness nor corrected local agent review is remote CI, external-user feedback or designated acceptance.
