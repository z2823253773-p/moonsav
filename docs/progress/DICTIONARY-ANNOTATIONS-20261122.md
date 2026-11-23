# 字典补充记录验证 · 2026-11-22

MoonBit 现在能读取文档行、变量集合、文件与变量属性，以及 C/D/E 三种多重响应集合。运行 `moonsav inspect survey.sav --json` 可查看 `dictionary_annotations`。导出包保留解析结果、源记录偏移和原始字节。检查器从原始记录重新解析内容，拒绝已修改且与原始记录不一致的字段。

实现依据为 [GNU PSPP 系统文件格式](https://pspp.benpfaff.org/manual/system-file.html)。样例包含 PSPP 2.0.1 实际生成的数据和独立编写的格式边界。真实生成样例再次用 PSPP 显示文档、属性与多重响应组。三个样例的数据与基础字典通过 ReadStat 对照，保留字节由单独的 Python 字段审计核对。自建样例覆盖空变量集合、长变量名引用、含中文的按字节计数标签及 subtype 19。含无法匹配变量引用的集合会作为原始记录保留并发出警告。

本地验证包括 168 项 Node 测试、三个 MoonBit 后端各 19 项测试、29 个损坏输入以及 ZSAV、大小端与 Windows 编码的独立回归。此前的工具语义分歧仍单列。许可证和合成语料来源见 [THIRD_PARTY](../../THIRD_PARTY.md)。当前证据覆盖公开格式资料及独立工具生成样例。IBM 26 文件、其余平台代码页和密码保护仍需验证。

```sh
npm run build
node --test tests/annotations.test.mjs
python tools/verify_annotations.py --output evidence/annotations-fresh
```

独立对照使用开发环境中的 pyreadstat 和 GNU PSPP。生成器为 `tools/generate_annotation_fixtures.py`，保存的实际样例和命令记录见 [证据汇总](../../evidence/dictionary-annotations-20261122/summary.json)。
