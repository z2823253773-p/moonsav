# Windows code page milestone

- **Behavior.** Accept Windows-874 and Windows-1250/1251/1253–1258 in the existing SAV/ZSAV read, inspect, export and bundle check workflows. Accept windows-N, cpN and numeric aliases. A known machine code can select a profile, and an explicit override keeps the existing precedence and warning. Reject undefined bytes and conflicting reliable declarations.
- **Implementation.** MoonBit chooses and validates the profile. The Node adapter uses deterministic tables generated from Python 3.12's strict codecs. Preserve the existing CP1252 and East Asian behavior. Ship the mapping provenance and the Python license with the tables. The byte core continues to require an adapter for non-UTF-8 reads.
- **Acceptance.** Compare UTF-8 and local-code-page representations of each synthetic survey, keeping string widths and source bytes distinct. Check decoded labels and data against Python, ReadStat and PSPP. Exercise malformed bytes, machine-only declarations, aliases, override, installed-package usage and the real bundle checker. Record any oracle disagreements instead of treating them as passes.

The [PSPP format documentation](https://pspp.benpfaff.org/manual/system-file.html) records these Windows encodings in system files. This establishes a testable subset of the IBM 26 target. The full producer inventory remains pending.
