# MoonSav current acceptance handoff

Updated2026-10-24 America/Phoenix. Workspace `/Users/henryz/Desktop/比赛/moonsav`, branch `implementation`, private remote [z2823253773-p/moonsav](https://github.com/z2823253773-p/moonsav).

**Frozen tested source:** `0afbe3443a93f6fd13e7211ba41cc970ca0b00a9`. **Source-tree SHA256:** `7a8e46aa59fb754213a574d807b316c42648e9ebcd861f9c5f38526db090869f`. Later commits are reporting/evidence only; current exact Git HEAD/clean/upstream and hashes are in ignored dist/delivery-state.json and must be checked live before later work.

Private repo creation/push/Actions were explicitly authorized. Final [run40073319985](https://github.com/z2823253773-p/moonsav/actions/runs/40073319985) succeeded on all four jobs: Windows2025, Ubuntu24.04, macOS15 and independent Linux oracles. Full local and Linux entries both produced17 supported_pass + AC09 expected_rejection29 vectors, zero failures/unexpected/not_run. **Designated acceptance remains pending**; this implementation has written no approval in docs/acceptance.

## Exact delivery

- `dist/moonsav-0.1.0.tgz`: 295135 bytes, SHA256 `9eaeacecd1c599a56a7fa22d392f9bf7dea4f6072b1a3e3250b85e8c6f7d76c5`.
- `dist/moonsav-source-0.1.0.zip`: 57644 bytes, SHA256 `3b3649ba4c966fbb19c66c325da54549fad92a1535998dc2702dc300fd84cd7c`.
- Build reports source0afbe34, dirty=false, actual moon0.1.20261023/moonc0.10.17+d971670cd. Original8ae93f2 archives remain unchanged in `dist/history/8ae93f2`; intermediate failed trial archives are not final delivery.
- Runtime CLI: Node24.15.0/ICU78.2 only; no MoonBit/Python/C compiler/runtime npm dependencies/network. Python consumer separately needs standard-library Python.

Read TASK_STATE, current docs/delivery-manifest.json, M4/M5, REMOTE_CI and evidence/remote-ci-final/cross-check.json. `evidence/local-ci-final-0af` is the actual clean local full run; `evidence/remote-ci-final/artifact/summary.json` is downloaded Linux proof, bound to the exact remote run/SHA. Full raw Actions logs and first/second failures are retained. Independent agent installed the exact final archives in a fresh directory and ran U1–U3; report under evidence/remote-ci-final/independent-artifacts.

## Reproduce on this host

Use new checkout/output paths. The clone omits ignored dist/dev/cache; copy existing exact archives from the original dist and verify SHA if testing the delivered bytes rather than a rebuild. Rebuilding creates a different build commit/provenance record and may change archive SHA.

```sh
git clone --no-hardlinks /Users/henryz/Desktop/比赛/moonsav /tmp/moonsav-acceptance-20261024
cd /tmp/moonsav-acceptance-20261024
python3.12 -m venv .dev/venv
.dev/venv/bin/python -m pip install -r requirements-dev.lock
PATH="/Users/henryz/Desktop/比赛/moonsav/.dev/moon-ci/bin:$PATH" MOONSAV_PSPP="/Users/henryz/Desktop/比赛/moonsav/.dev/pspp/bin/pspp" .dev/venv/bin/python tools/verify.py --all --require-public --require-pspp --output evidence/independent-run
.dev/venv/bin/python -m unittest discover -s tests -p '*_test.py'
```

The final unittest also needs a supported Moon on PATH if the shell default is not one of the two declared pairs. Existing default old pair works on this host. New Moon/core were installed only under .dev/moon-ci; the old global installation was not changed. Old official pinned downloads403, so remote CI uses the explicitly fixed downloadable0.10.17+d971670cd pair. Exact versions/hashes/probes are retained. Another OS must install that declared native toolchain/core/Node/dev dependencies/PSPP, not copy macOS binaries.

On the new source workspace, bundled `examples/consumer` already has native moon.mod/moon.pkg/moon.work. Run `moon run . --target js` there; also native/wasm-gc on declared platforms. Local module resolution is via workspace, with no unpublished registry dependency. Follow README for a separate consumer layout.

Public data are fetched into ignored cache when absent and checked against frozen SHA. No private samples are required. Two source licenses/provenance and65449-cell full comparison are recorded; space normalizations are explained. The Mac supplementary-plane ReadStat/iconv limitation is preserved; Linux AC06 passed without that limitation. No universal compatibility percentage is inferred.

## Evidence scope and pending acceptance

Local/Linux/macOS:49 Node tests (38 shared +11 POSIX) and7 byte-core tests on each JS/native/wasm-gc. Windows:38 shared tests,7 each JS/wasm-gc, own actual archive install/Unicode-space smoke. Windows native/POSIX crash/ACL equivalence is not claimed. Each CI platform builds its own archive from source; the exact local downloadable artifacts were independently installed on macOS. The Linux full entry also covers schemas, both oracles, public files, source consumer and workload. These distinctions remain visible in M4.

A later report-only commit uses [skip ci] to avoid duplicate tests; this is not a test pass. Compare its product files with source0afbe34 and the source digest. Overall PRD acceptance requires the original acceptance chat's independent assessment. Agent review is not that approval, a human-user trial, organizer approval or a public release. No npm/Mooncakes release or registration occurred.

## Copy-ready continuation

> 请独立验收 `/Users/henryz/Desktop/比赛/moonsav`。先现场核对 HEAD、dirty、origin 和私有可见性；当前代码冻结提交为 `0afbe3443a93f6fd13e7211ba41cc970ca0b00a9`，后续只允许文档/证据差异，源码摘要应为 `7a8e46aa59fb754213a574d807b316c42648e9ebcd861f9c5f38526db090869f`。核对 docs/delivery-manifest.json、dist/delivery-state.json 和两份最终归档 SHA，读取当前 M4/M5、REMOTE_CI、最终本地与 Linux 下载报告及原始 Actions 日志。远端 run40073319985 四个任务均成功，但不要只凭实施者自报批准。请从新目录复现同一入口和归档 U1–U3，重点检查编码变体/长字符串/缺失、重算哈希后的恶意 bundle、事务与资源边界、不同工具链和消费者工作区。按 supported_pass/supported_fail/expected_rejection/unexpected_result/not_run 分类，保留失败命令/exit/输入。验收材料仅写 docs/acceptance，产品继续由实施对话改，避免双写。Windows 的 POSIX/native未测范围、Mac oracle限制和代理审查身份必须单列。已授权私有 GitHub 推送/CI；未授权公开发布、npm/Mooncakes发行或赛事报名。
