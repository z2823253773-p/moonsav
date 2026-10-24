# MoonSav local candidate handoff

Workspace: `/Users/henryz/Desktop/比赛/moonsav`
Branch: `implementation`
Tested product SHA: `8ae93f2b46ab7a81acbf7a120564c493693324fb`
Source-tree SHA256: `e77cf705f5e878e10a49cbb040336af9d990fb65b2e201ffab1502a29d936bf6`

Local M1–M5 delivery candidate is implemented and the AC01–AC18 local entry passed (17 supported_pass + AC09 expected_rejection, zero failures/skips). Overall PRD acceptance is pending remote Linux/Windows runs and the designated acceptance chat. End-of-delivery exact Git SHA/clean state is in dist/delivery-state.json and must be refreshed with `git rev-parse HEAD; git status --short` if the tree changes.

Start with TASK_STATE.md, docs/progress/M4.md, M5.md, INDEPENDENT_REVIEW.md, docs/delivery-manifest.json and evidence/final-20261023-01/summary.json. The run ledger records the original source SHA, truthful dirty status and commands; later report commits do not replace it. Archives below were actually installed/extracted and tested; they were not published.

- CLI: `dist/moonsav-0.1.0.tgz`, SHA256 `26e79e5f6974551bcbea967090992ad771c91e363f3b30b7e53f0e2f24bfad3e`.
- Byte library: `dist/moonsav-source-0.1.0.zip`, SHA256 `6137341fc0be5e17d7a15bb4f571b9e726e582ba19a02df4f22ecb2411c53cce`.
- Existing isolated developer Python: `.dev/venv/bin/python` (3.12.13), fixed oracle dependencies in requirements-dev.lock.
- Existing GNU PSPP: `.dev/pspp/bin/pspp` (2.0.1), independently executed only for development.

## Same-host independent acceptance

Use a new checkout/output directory. The first command clones the committed product and reports, not ignored local archives, public caches or dev environments. To test the existing exact archives, copy them from the original dist and verify their hashes first; rebuilding creates a different build record/tar hash.

```sh
git clone --no-hardlinks /Users/henryz/Desktop/比赛/moonsav /tmp/moonsav-independent-acceptance
cd /tmp/moonsav-independent-acceptance
python3.12 -m venv .dev/venv
.dev/venv/bin/python -m pip install -r requirements-dev.lock
MOONSAV_PSPP=/Users/henryz/Desktop/比赛/moonsav/.dev/pspp/bin/pspp .dev/venv/bin/python tools/verify.py --all --require-public --require-pspp --output evidence/independent-run
```

The public-cache step downloads two frozen licensed files when absent and checks SHA; private data are not required. All evidence payloads remain ignored. Need Node24.15.0/ICU78.2 and moon0.1.20260713/moonc v0.10.4+2cc641edf; do not silently substitute versions. On another host install the declared dev/oracle environment; the supplied macOS arm64 PSPP conda lock is not a Linux/Windows validation result.

Acceptance must inspect actual results/diffs, not merely command exit0. Confirm every case and classification, compare source/corpus/artifact hashes, review unsupported variants and decoder identity, test U1–U3 from installed artifacts, and inspect the retained failures. Full public comparison is65449 cells with source-string/one-label trailing-space normalization explained. Extra GB18030 supplementary-plane fixture has a preserved Mac ReadStat/iconv limitation; it passes independent GNU PSPP and mapping/Python checks. No compatibility percentage is inferred.

## Copy-ready continuation for the designated acceptance chat

> 请独立验收 `/Users/henryz/Desktop/比赛/moonsav`，先现场核对分支、HEAD、dirty、docs/delivery-manifest.json、dist/delivery-state.json 和两份归档 SHA。产品测试提交为 `8ae93f2b46ab7a81acbf7a120564c493693324fb`，最终报告提交可能随后出现；先确认差异只含文档/证据。阅读 TASK_STATE、PRD r0.2、M4/M5 和最终 run.json/summary.json，再从全新目录复现同一验收入口及归档 U1–U3，不把实施者自报当批准。按 supported_pass/supported_fail/expected_rejection/unexpected_result/not_run 分类，保留失败输入/命令/exit。验收材料只写 docs/acceptance/；产品由实施对话改，避免双写。重点检查编码非单射边界、长字符串/缺失匹配、重新计算哈希后的恶意 bundle、事务提交与资源限制。当前 Linux/Windows 远端 CI 未运行，独立代理审查不是指定验收或外部用户访谈；必须单列这些缺口。未授权公开推送、发布、报名，不执行这些操作。
