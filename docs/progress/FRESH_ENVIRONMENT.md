# Full fresh-environment reproduction

2026-10-23 America/Phoenix. Source SHA912742888038e85c459a2be12c3d0cd0fd45f0a7, branch implementation. This closes the earlier local gap where the clean-clone check only reran AC01 using the existing developer interpreter.

A new no-hardlinks Git clone started clean. A new Python3.12 venv installed the exact requirements-dev.lock successfully; public files were downloaded into its initially empty cache and verified against frozen hashes. The complete `tools/verify.py --all --require-public --require-pspp` entry exited0:17 supported_pass, AC09 expected_rejection29 vectors, no supported_fail/unexpected_result/not_run. All48 Node tests and7 byte-core tests on each of three backends passed. Package installation, both oracles, full public comparison and seeded performance ran in the new checkout.

The Moon/Node toolchain and GNU PSPP2.0.1 executable are the same pinned host installations as before; this is a new checkout/Python/cache proof, not an independent fresh OS or a new PSPP build. No Docker daemon/Colima VM was running; no VM was started. Remote CI and designated acceptance remain unrun/pending. Original acceptance chat had no new feedback when its compact status was checked.

Fresh package build records dirty=false and source_tree_sha256 e77cf705f5e878e10a49cbb040336af9d990fb65b2e201ffab1502a29d936bf6, exactly equal to the tested delivery source. Its artifact hashes/build SHA differ from the earlier archive because build provenance differs. Those fresh archives live in ignored .dev/clean-full-20261023/checkout/dist and are not silently substituted for the independently reviewed delivered files. Original dist archive hashes were rechecked unchanged.

Evidence: evidence/clean-full-20261023/setup-run.json (clone/venv/pip/full command and exits); result.json and acceptance/summary.json (all cases); acceptance/run.json and nested result/log files; build.json (clean provenance). Public raw rows/bundles remain in ignored payloads, not copied into committed evidence. This run is implementer macOS reproduction, not designated acceptance or remote Linux/Windows proof.

To repeat, clone the committed repo into a new directory, create a new Python3.12 venv, install requirements-dev.lock, use the declared pinned Moon/Node versions and set MOONSAV_PSPP to an independently installed2.0.1 executable, then run the full entry with a new output directory. docs/FINAL_HANDOFF.md contains the exact same-host commands.
