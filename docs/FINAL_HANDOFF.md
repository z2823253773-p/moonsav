# MoonSav designated re-acceptance handoff — 2026-11-06

Workspace `/Users/henryz/Desktop/比赛/moonsav`, branch implementation; private [repository](https://github.com/z2823253773-p/moonsav). Frozen source `e453463ae8206fffb8a6fae860168d4a2be8c6ae`, digest `f1334fe3947b42e0dba4e70a6ac3f5340b25c6498e1da3ca756004fc7cc0dfd7`. Later commits are reporting/evidence only; verify live HEAD/status/upstream and product diff. Acceptance-owned docs/acceptance remains untracked and untouched.

The original CHANGES_REQUIRED F1–F5 were repaired in a3c4b22. This follow-up fixes a CSV iterator descriptor leak during failed bundle checks, without changing formats/options/semantic errors. Four RED→GREEN regressions,11 independent before/after paths and exact-tgz resource replay verify cleanup. docs/CONTRACTS.md covers all supported public objects/fields/defaults/units/ownership/errors/state and is included in both archives. STREAM_CLEANUP and CONTRACT_HARDENING record the respective repair scopes.

| Archive under dist | Bytes | SHA256 |
| --- | ---: | --- |
| moonsav-0.1.0.tgz | 310035 | `9817d55a6880693ecaf615c3ce7da721b4eda951202371c2d410588bb29f5bc7` |
| moonsav-source-0.1.0.zip | 73493 | `a5f7ad5ae55a0a81755d2cbc01e788960c0ba7bdf3a16481f0972f9119b35618` |

Build dirty=false, e453463. Earlier exact packages/manifests remain dist/history/a3c4b22,0afbe34,8ae93f2. Clean full-run package members/install commands are evidence/stream-cleanup-20261106/full-run/packages/result.json; independent exact-archive consumption is independent-review/archive-consumer-result.json. Only Node is needed at runtime; Python standard-library reader is separate. Both compiler/core pairs consume the source archive on JS/native/wasm-gc.

Local clean clone and Linux entry both17 supported_pass + AC09 expected_rejection29 vectors. Public65449-cell ReadStat/PSPP comparison has no unexplained difference; raw normalizations and Mac supplementary-plane oracle limitation are retained. Both local toolchains112 Node and14 core per backend. [New CI](https://github.com/z2823253773-p/moonsav/actions/runs/42248646372) all4 jobs succeeded; M4 distinguishes Windows101 shared tests from Linux/macOS112 and omitted Windows native/POSIX. Each platform builds its own artifacts; exact downloadable bytes were independently consumed on macOS.

## Independent reproduction

Verify docs/delivery-manifest.json and dist/SHA256SUMS. On this host, challenge the exact delivered tgz (new output path required):

```sh
.dev/venv/bin/python docs/acceptance/2026-10-24/reproduce_findings.py --root . --output .dev/reaccept-new-path
```

Portable ownership replay: from a built repository or extracted npm root, run `node /absolute/path/to/evidence/stream-cleanup-20261106/independent-review/replay.mjs`. It loads the adjacent recorded baseline, uses actual runtime from current working directory and creates a fresh OS temporary evidence directory. It compares11 success/failure paths and their real descriptors; it does not alter product/acceptance files.

For full source verification, clone into a new path and run (existing fixed local tools/cache dependencies reused, not a from-zero installation claim):

```sh
git clone --no-hardlinks /Users/henryz/Desktop/比赛/moonsav /tmp/moonsav-reaccept-new
cd /tmp/moonsav-reaccept-new
PATH="/Users/henryz/Desktop/比赛/moonsav/.dev/moon-ci/bin:$PATH" MOONSAV_PSPP="/Users/henryz/Desktop/比赛/moonsav/.dev/pspp/bin/pspp" /Users/henryz/Desktop/比赛/moonsav/.dev/venv/bin/python tools/verify.py --all --require-public --require-pspp --output .cache/reaccept-full
```

A clone omits dist; copy and SHA-check exact existing archives for exact-byte consumption. Rebuilding changes provenance/hashes. Other machines need platform-native declared dependencies; do not copy macOS binaries. Public inputs are downloaded and SHA-checked if absent. Both old/new fixed toolchains remain unchanged; newer formatting aliases must not silently break old compiler support.

## Copy-ready review brief

> 请重新独立验收 MoonSav 冻结源码 `e453463ae8206fffb8a6fae860168d4a2be8c6ae`，先核对 live HEAD/upstream/dirty、私有可见性、source digest和两份精确归档 SHA。阅读 CONTRACTS、STREAM_CLEANUP、CONTRACT_HARDENING、M4/M5及 evidence/stream-cleanup-20261106。原五项反例已修复；本轮另修复失败检查时 CSV 句柄未释放。请重放未修改的 reproduce_findings.py 对新 tgz 的反例，独立消费归档/复跑完整入口，并用包内 runtime 复查文件句柄、异常分类、重试和预算边界。远端42248646372四作业通过，但平台自己的构建不等于本地归档在全部系统逐字节安装。保留 Windows native/POSIX未测范围、Mac oracle限制和外部试用缺口。请只在 docs/acceptance 写验收结果，不改产品；最终通过由原指定验收对话给出。只授权私有推送/CI，无公开发行、赛事报名或组织方认可。
