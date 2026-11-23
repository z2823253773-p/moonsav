# Windows 代码页阶段验证 · 2026-11-22

本阶段为 SAV 读取增加 Windows-874、1250、1251、1253–1258。MoonBit 负责从字典和机器记录选择编码、检测冲突并保留来源。Node 适配器离线使用冻结字节映射。映射表由 CPython 3.12 的严格解码表生成，未定义位置返回错误。用户可使用 `--encoding` 指定已知源编码，检查报告会注明覆盖。旧 CP1252、GBK 和 GB18030 配置沿用原有规则。

以九组调查做逐字段验证。每组使用同一份字符串编号、一种该代码页可表示的本地文字、变量标签、值标签和数值缺失定义，分别以 UTF-8 和本地代码页保存。对照比较保留原字节，不用 Unicode 归一化掩盖差异。18 份文件均由合成数据生成并完成导出及 bundle 校验。

| 验证项 | 本地结果 |
| --- | --- |
| Node 回归及离线安装包 | 163/163 通过，已安装 CLI 读取、导出、校验 Windows-1251，包内含映射许可 |
| MoonBit JS、native、wasm-gc | 各 19/19 通过 |
| ReadStat | 18/18 逐字段对照通过 |
| GNU PSPP 2.0.1 | 17/18 与输出逐字符一致，1 个保留解释明确的编码分歧 |

Windows-1258 的越南文样例含组合标记。MoonSav、原始映射与 ReadStat 保留解码后的原序列。该环境下 PSPP 将这一序列组成 NFC，故原始逐字符对照计为失败。验证器仅在三个文字单元格完整匹配预期 NFC、其余字段无差异时分类为已知分歧，报告仍保留原失败状态。

附带的 [证据汇总](../../evidence/windows-codepages-20261122/summary.json) 记录构建指纹、命令、退出码、样例哈希和分歧。源数据为仓库自建合成样例。映射来源、许可证及开发工具边界见 [第三方说明](../../THIRD_PARTY.md)。

```sh
npm run build
npm test
python tools/verify_windows_codepages.py --output evidence/verify-windows-fresh
```

独立对照要求安装开发环境中的 pyreadstat 和 GNU PSPP。输出目录须为新目录。CPython 3.12.13 可运行 `python tools/generate_windows_codepages.py` 重建映射与样例。

IBM 26 生产者的完整 locale 清单仍需验证。后续还要覆盖其余编码、字典语义、密码保护和原版回读，再进行完整交付验收。Windows 阶段的跨平台 CI 已加入验证命令，尚待远端运行。
