# MoonSav designated re-acceptance handoff — 2026-11-06

Workspace `/Users/henryz/Desktop/比赛/moonsav`, branch implementation; private [repository](https://github.com/z2823253773-p/moonsav). Frozen source `a3c4b225008c9af2c4fac3d60a63339ada8c19c7`, digest `7e73f6a651c53450b84a93a0c65815e91829112fbcb4dea25a0989e3ff6b2ace`. Later commits are report/evidence only; verify live HEAD/status/upstream and source diff. Acceptance-owned docs/acceptance remains untracked and untouched; do not equate that with dirty product source.

Original designated report returned CHANGES_REQUIRED. All F1–F5 are now repaired with regression/boundary evidence and unchanged final-tgz replay (exit0). The object audit also covers nested shapes, strict Node options, encoding tokens/identities, framing budgets and ownership snapshots. docs/CONTRACTS.md is the source-backed public contract and is inside both exact archives.

| Archive under dist | Bytes | SHA256 |
| --- | ---: | --- |
| moonsav-0.1.0.tgz | 309965 | `3be70b3312b6f632d1c03a2aea5106255ed3f71c6a2260666191b70e9371dea0` |
| moonsav-source-0.1.0.zip | 73425 | `958968861f79eb08eaaed87368f117bfb95e94420f780ea9a20c3ac283b49517` |

Build dirty=false, clean a3c4b22. Earlier archives preserved in dist/history/0afbe34 and8ae93f2. Exact inspected members and offline installation are evidence/contracts-20261105/full-run/packages/result.json. Independent exact-archive15-command consumption is in independent-review/archive-consumer-result.json. Node only runtime; separate Python standard-library reader; source JS/native/wasm-gc consumers passed both fixed compiler/core pairs.

Local clean clone and Linux independent entry both17 supported_pass + AC09 expected_rejection29 vectors. Public65449-cell ReadStat/PSPP comparison has no unexplained difference. Both toolchains locally108 Node and14 core each backend. [Remote CI](https://github.com/z2823253773-p/moonsav/actions/runs/42243643477) all four jobs succeeded; M4 spells out97 Windows shared tests versus108 Linux/macOS and omitted Windows native/POSIX. Remote platform jobs build their own archives; exact downloadable local bytes were independently consumed on macOS. Raw local/remote results and warning/normalization/oracle limitations remain intact.

## Reproduce independently

First verify archive SHA256 against docs/delivery-manifest.json and dist/SHA256SUMS. To challenge the delivered bytes without a rebuild:

```sh
.dev/venv/bin/python docs/acceptance/2026-10-24/reproduce_findings.py --root . --output .dev/reaccept-new-path
```

Use a new output path. This script remains acceptance-owned/unchanged. Original RED and current GREEN are both in evidence/contracts-20261105. A fresh clone omits dist; copy the exact verified archives there for exact-byte testing. A rebuild changes provenance/archive hashes.

For a source clone full entry on this host, use existing isolated Moon/PSPP binaries and fixed Python interpreter (not a claim to install dependencies from zero):

```sh
git clone --no-hardlinks /Users/henryz/Desktop/比赛/moonsav /tmp/moonsav-reaccept-new
cd /tmp/moonsav-reaccept-new
PATH="/Users/henryz/Desktop/比赛/moonsav/.dev/moon-ci/bin:$PATH" MOONSAV_PSPP="/Users/henryz/Desktop/比赛/moonsav/.dev/pspp/bin/pspp" /Users/henryz/Desktop/比赛/moonsav/.dev/venv/bin/python tools/verify.py --all --require-public --require-pspp --output .cache/reaccept-full
```

Other machines must install platform-native declared dependencies; do not copy macOS binaries. Public files are downloaded and SHA-checked when cache absent. Original source toolchain was not replaced. Never run the newer formatter over old-compatible source without verifying old compiler compatibility.

## Copy-ready review brief

> 请重新独立验收 MoonSav。原 CHANGES_REQUIRED 的五项反例已在冻结源码 `a3c4b225008c9af2c4fac3d60a63339ada8c19c7` 修复；先核对 live HEAD/dirty/upstream、私有可见性、source digest和 docs/delivery-manifest.json 两份精确归档 SHA。阅读 CONTRACTS、CONTRACT_HARDENING、M4/M5 和 evidence/contracts-20261105。重放未修改的 reproduce_findings.py 对最终 tgz 的反例，核查相等/超限预算、nominal 两种宽度约定、编码覆盖、规范数值、封闭字段、Node 参数和所有权；自行消费精确 tgz/source zip 与复跑完整入口。不能仅凭实现者或代理审查批准。远端42243643477四作业通过，但平台自己的构建不等于精确本地归档在所有系统逐字节安装。保留 Windows native/POSIX未测范围、Mac oracle限制与外部试用缺口。请仅在 docs/acceptance 写验收材料，不修改产品；通过结论由原指定验收对话给出。授权仅含私有推送/CI，无公开发行、赛事报名或组织方认可。
