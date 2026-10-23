# MoonSav 需求与技术研究

版本：r0.1；调查日期：2026-10-23（America/Phoenix）。状态：首轮研究完成，产品未实现，设计待确认。

## 1. 结论及证据等级

- **事实**：目标目录起初不存在；已逐级检查 `/AGENTS.md`、`/Users/AGENTS.md`、`/Users/henryz/AGENTS.md`、`/Users/henryz/Desktop/AGENTS.md`、`/Users/henryz/Desktop/比赛/AGENTS.md`，均不存在。父目录不是 Git 仓库。未修改相邻项目，也未读取其私有数据。
- **事实**：本轮公开检索未发现明确的 MoonBit SPSS SAV 读取库；这不是全面不存在证明，更不覆盖未公开报名项目。详见第 2 节。
- **事实**：ReadStat、pyreadstat、haven 提供成熟参照，但后二者共享 ReadStat；它们不是三套独立解析器。[S1–S3]
- **事实**：GNU PSPP 开发者文档提供系统文件结构说明。它是 PSPP 项目对兼容格式的文档，不能称为 IBM 发布的完整二进制官方规范。[S4] IBM 文档确认 SAV 同时包含数据与字典。[S5]
- **建议**：继续固定 MoonSav 方向。以 MoonBit 实现格式解析、传统压缩解码和语义层，复用平台 I/O 与严格字符解码；先提供 Node.js CLI 和 MoonBit 字节库。不是 ReadStat 包装器。
- **待验证**：任何 `.sav` 的 MoonBit 读取、实际字段一致性、依赖可编译性、跨平台、安装、性能、CI。当前没有产品兼容性通过记录。
- **待确认**：十一月正式章程、是否计入十月预研工作、初审状态、发布命名空间。未报名、未公开推送、未获得初审认可。

## 2. 重复性、相邻实现及暂名

本轮使用 GitHub 连接器、GitHub CLI、网页搜索及 Mooncakes 公开 API。查询与返回摘要保存在 [discovery.json](evidence/2026-10-23/discovery.json)。注册表证据见 [registry-audit.json](evidence/2026-10-23/registry-audit.json)。

| 检索面 | 查询或范围 | 本次结果 | 解释限制 |
| --- | --- | --- | --- |
| GitHub 仓库 | `MoonBit SPSS`、`MoonBit sav`、`MoonBit readstat`，以及 `spss/sav/readstat language:MoonBit` | 未返回直接同类 | 仓库语言、描述和索引不完整 |
| GitHub 代码 | `$FL2`、SPSS、readstat，限定 MoonBit；另用 `gh search code` 核查 | `$FL2` 返回空；SPSS 命中主要是字体/媒体编码数据；readstat 命中 ReadStatus 等无关标识符 | 搜索大小写和子串匹配带来误报；未遍历所有仓库/分支 |
| GitHub README | `MoonBit SPSS in:readme` | 返回语言目录类仓库，未发现 SAV 实现 | 不覆盖无 README、私库和未索引代码 |
| Mooncakes | `/api/v0/modules` 的 3240 条模块元数据 | 名称或描述未匹配 spss/readstat/moonsav | 不是对 3240 个源码包的全面扫描 |
| Mooncakes 搜索 | `spss`、`sav`、`readstat`、`MoonSav` | spss 返回空；其余模糊命中逐项摘要未显示直接同类 | 模糊搜索命中 save、ReadStatus 等不等于 SPSS |
| 网页索引 | MoonBit + SPSS/ReadStat、`site.mooncakes.io` 等 | 未找到明确直接同类 | 未公开报名与私有群信息不可见 |
| 项目名 | GitHub `MoonSav` | 存在 `UtsavBabu/moonsav`，查询时 size=0、默认分支 prod | 仅是此次元数据；不能保证名称独占或注册表可发布 |

**结论措辞**：可以说“在截至调查日的公开检索范围内，尚未发现明确的 MoonBit SAV 读取库”，不能说“首个”“唯一”“已完成全面查重”。MoonSav 继续作为暂名，发布前复查 owner/name 及商标/包名情况；仓库名重名本身不要求重新选题。

相邻能力：

| 实现 | 核实内容 | 与本项目的关系 |
| --- | --- | --- |
| [ihb2032/MoonFrame](https://github.com/ihb2032/MoonFrame/tree/8717a723800aa448ed943169433ef657fb837230) | README 描述 CSV/JSON/NDJSON 与表格运算；树中有 CSV I/O，未见 SAV 路径 | 后续消费方；本期不扩建 DataFrame |
| [sdjm5/moonbit-dataframe](https://github.com/sdjm5/moonbit-dataframe/tree/737ab8b8ca7bd8c2ad3b322fe5d7769cfcbb5feb) | README 描述 CSV/JSON 内存表 | 相邻表格工具，不是当前发现的直接同类 |
| [moonbitlang/x encoding](https://github.com/moonbitlang/x/blob/812f9a6a72754cfd961a6d6ebc7eaf76c0ff72c0/encoding/pkg.generated.mbti) | 公开接口有 UTF8/UTF16 等及抛错/有损接口；不能据此推出 GBK 支持 | UTF-8 严格解码候选 |
| [0Ayachi0/GB18030](https://github.com/0Ayachi0/GB18030/tree/3116f70ebe2f98dd691daf5a4b4b0ec7769c0e88) | 注册表 0.1.0、Apache-2.0；README 声称错误返回 | 候选，未运行审计，不能把自述覆盖率当当前证据 |
| [LL728/moon_encoding](https://github.com/LL728/moon_encoding/tree/dbb5a3b69c4b4cc35b3eed4b73d905c688008736) | 注册表 0.2.0；README 明确默认解码替换非法字节 | 不能直接满足“不静默替换”；且 WHATWG latin1 别名不能当成 ISO-8859-1 |

不为“原生”重新实现所有通用基础设施。新增贡献必须集中于 SAV 解析、记录关联、逻辑变量重组、缺失与标签语义、可复现兼容性和导出契约。

## 3. 一手资料与最高风险

### 3.1 格式结构

GNU 文档概述了文件头、字典记录与数据区；ReadStat 当前源码提供可追溯实现参照。[S4, S6] 首期限定 `$FL2`、小端整数与 IEEE754；压缩字段为 0 或 1。对 `$FL3`/zlib、其他浮点表示及大端文件返回具体不支持错误，不能凭扩展名判断。

关键记录研究清单：type 2 变量；type 3/4 值标签与物理变量索引关联；type 6 文档；type 7 有长度扩展；999 字典结束。扩展 3/4 用于机器信息和缺失哨兵、13 长变量名、14 超长字符串、16 扩展行数、20 编码、21/22 长字符串标签及缺失。物理槽位、字典变量索引、公开逻辑列不可混为一谈。[S6]

GNU 各章节多次请求超时；本次成功保存概述，超长字符串章节从 GNU 索引内容读取，其余细节以 ReadStat 源码交叉检查。超时及 404 已留在证据中，未伪称全文均可读取。

### 3.2 传统字节码压缩

ReadStat 的解码器按八个控制码处理，控制块与后续八字节数据交织；不能按一行一块重置状态。0 跳过、252 结束、253 跟随原始单元、254 空格、255 系统缺失，其余码结合文件头 bias 还原数值。[S7] 必测跨行、跨控制块、字节流截断、提前结束、非默认 bias、行数未知与声明不符。不能把压缩字节数当解压资源预算。

### 3.3 字符串与长字符串

宽度是**字节数**。常规字符串以八字节物理单元延续；超过 255 字节的逻辑变量另有分段和扩展映射。GNU 文档揭示了 252 与 255 相关的分段布局，不能简单把每段尾部当填充全部裁掉。[S8] 实现前以原始字节、中文跨单元/跨段、255/256/504/505 等边界对照，重组完成后才解码。长字符串值标签与用户缺失由扩展记录处理；暂不支持时必须报错，不得偷偷丢掉。

### 3.4 缺失、标签和显示格式

系统缺失是专用数值表示，不能把任意极小数、NaN、零或空字符串推定为缺失。用户缺失可能为离散值、范围及范围加离散值；数值本身仍须保留。[S4, S6] pyreadstat 对照必须设置 `user_missing=True`，关闭日期自动转换及值标签替换，避免在对照前丢语义。[S2] 字符串的空白与用户缺失定义分开判断。

日期显示格式不改变底层数值类型。v0.1 保留 print/write 格式代码、宽度、小数位和底层 double，不实现自动日期转换；不可用操作系统本地时区解释无时区的 SPSS 时间。[S3]

### 3.5 编码

优先读编码扩展，其次映射机器信息代码；无可靠声明则要求显式覆盖，不能默认“中文一定 GBK”。记录原始声明、选择来源、覆盖值及最终解码器。UTF-8、Windows-1252、GBK、GB18030 是首期建议编码范围；ISO-8859-1 与 Windows-1252 不合并。

本机只做了环境探测：Node v24.15.0、ICU 78.2 的 `TextDecoder` 可创建上述编码解码器；`fatal:true` 对 UTF-8/GBK/GB18030 的单独 0x81 拒绝。Windows-1252 的该字节并未被拒绝，说明不能用单一非法样本推断全部编码。此结果既不是完整 codec 审计，也不是 SAV 读取证明。

## 4. 样例与独立性

| 来源 | 已确认状态 | 后续用途及边界 |
| --- | --- | --- |
| pyreadstat 写入器 | 源码与公开写入 API 已查；本机未安装 | 独立于 MoonSav 的生成器。生成 none/row-compression、标签、字符串、缺失；它和 ReadStat 对照属于同一家族 |
| GNU PSPP | 文档已定位；本机未检测到可执行程序 | 第二解析/生成家族。通过固定版本容器或 CI 安装进行交叉核验，不复制其 GPL 实现到产品 |
| pyreadstat 仓库 `test_data` | 定位 sample.sav、sample_missing.sav、missing_char.sav、不同语言文件 | 开发回归候选；仓库许可证和单个文件来源分开审核，不能把软件许可自动套到所有数据 |
| ReadStat resources | 定位 `sav_missing_continuations.sav` | 边界候选；许可证及来源核对后再纳入 |
| Figshare `data.sav` | 官方 API 返回作者 Yuanming GUO、DOI `10.6084/m9.figshare.24792756.v1`、CC BY 4.0、379254 字节、文件 id 43604517 | 发布者标记为 survey data 的公开真实样本候选；不是用户提供或用户反馈；内容、标识符与适用范围还需读取审计 |
| Figshare 另一项研究 | 官方 API 返回 Rosa Vilaseca 等作者、DOI `10.6084/m9.figshare.12459449.v1`、CC0、33420 字节；描述为父母社会人口学及 PICCOLO 分数 | 不同作者/研究来源、同一托管平台；本次仅取公开元数据，未下载数据内容；须先筛查标识符，不作为首个演示数据 |
| 自建损坏向量 | 尚未生成 | 从有明确来源的合成样例定点变异，固定随机种子、变异位置与期望错误 |

Figshare 官方元数据已保存于 [figshare-24792756.json](evidence/2026-10-23/figshare-24792756.json)。网页抓取 403 后改用官方 API，无登录、无绕过访问限制。公开原文件已下载至临时研究缓存，379254 字节，与发布者 MD5 一致；SHA256 为 `e2b7f41ad4d0e3cc22c12db41976b755a68058ea706d80c1b0370d129b3814b6`。Python 标准库仅读文件头，观察到 `$FL2`、compression=1、声明 634 cases、336 个物理八字节单元；**336 不等于逻辑变量数，634 尚未通过全量读取验证**。证据见 [public-file-header.json](evidence/2026-10-23/public-file-header.json)。它不是 MoonSav 兼容性证明。原文件暂不纳入项目；后续入库须记录归属、许可、URL、原始哈希、来源版本及筛查结果。公开性不保证无个人信息。

最低真实兼容性门槛：至少 2 个不同来源的公开实际文件，其中至少 1 个是研究/调查数据；两种目标压缩模式有真实或独立工具生成的证据；必含独立于 ReadStat 的 PSPP 家族对照。当前均**未完成 MoonSav 验收**。不能用大量同一生成器的文件替代来源多样性。

第二项研究的元数据见 [figshare-12459449.json](evidence/2026-10-23/figshare-12459449.json)。这只是备选语料定位，不能以两个元数据条目替代两份文件的实际兼容性验收。其许可信息来源为 [Figshare 官方 API](https://api.figshare.com/v2/articles/12459449)。

## 5. 赛事核查：十一月不得借用十月规则

从 [MoonBit 中文官网](https://www.moonbitlang.cn/) 的年度黑客松链接定位到 [Hackathon2026](https://moonbitlang.github.io/Hackathon2026/)，再读取[官方页面源码固定版本](https://github.com/moonbitlang/Hackathon2026/blob/a879c208b261ca500f65707d42504d06572fa9b0/src/App.tsx)。实际部署 HTML 引用 `index-Cb3Bwakq.js`，已下载用于交叉核查。旧 OSC2026 页面是另一活动入口，仍有八月内容，不能替代本次赛期通知。

当前公开内容写明的是十月赛。一般工程要求涉及 MoonBit 主实现、公开仓库和连续开发记录、README/示例/测试、实质新增工作、来源及开源许可。以上作为本项目的工程基线，不擅自宣布其已适用于十一月。

| 事项 | 截至调查日状态 |
| --- | --- |
| 十一月正式报名/验收截止时间及时区 | 未确认；不把十月 31 日写成本项目截止日 |
| 十一月报名次数、组队与材料清单 | 未确认；不沿用十月数字 |
| 十月研究/代码是否计入十一月新增工作、初审前能否开发 | 未确认；现在如实保留预研记录，不声称满足工作计入规则 |
| 十一月必须 CI / Mooncakes 发布与具体证明 | 未确认；我们主动准备 CI 和可安装包，公开发布另按授权 |
| 选题的个人适用性 | 用户有数学及科研背景；尚无证据证明真实课题组需求或既有使用体验 |
| MoonSav 初审 | 尚未申报且无认可证据；仓库和内部 TASK_STATE 都不能证明通过 |

本轮没有发送邮件、群消息、提交表单或改变任何外部报名状态。若正式通知只在群内，后续需要用户提供其内容；目前不影响写 PRD，不为此先行打断。

## 6. 本地环境和依赖决策

当前只读检查：Darwin arm64；moon `0.1.20260713 (75c7e1f 2026-07-13)`；moonc `v0.10.4+2cc641edf (2026-07-15)`；Python 3.12.13；Node v24.15.0。`pyreadstat` 未安装；未检测到 R、PSPP。未升级工具链或安装依赖。

工具链比已见生态包要求旧，不能承诺所有依赖可用。M1 在隔离目录固定可工作的版本，先验证 MoonBit Double/UInt64、Bytes 和 JS 互操作。开发 Python 虚拟环境与 PSPP 仅用于验证，不进入产品运行依赖。JS CLI 用 Node 内置 fs/crypto/TextDecoder；默认不依赖 C 编译或 Python。库纯字节核心优先覆盖 wasm-gc/js/native，CLI 首发 Node，平台兼容性以 PRD 的证据矩阵为准。

## 7. 风险结论与下一步

最高风险不是演示界面，而是物理变量重组和语义保留。设计确认后先生成一份带数值/字符串/标签/系统缺失/用户缺失的文件，MoonBit 逐字段读取并生成差异报告；随后换压缩方式、加多字节与超长字符串。最早失败即保留并修复，范围变更必须更新 PRD。

未确认十一月规则可能影响参赛资格，但不妨碍做一个真实工具。工程完成、真实兼容性通过、开发者复现、公开发布、初审通过和赛事验收是六种不同状态。

## 来源索引

- S1：[ReadStat README](https://github.com/WizardMac/ReadStat/tree/4fbf1d8e516513dc06c7a73aab03b3daced87d4f)。MIT C 库与 CLI、支持格式及语言绑定。
- S2：[pyreadstat 官方文档](https://ofajardo.github.io/pyreadstat_documentation/_build/html/index.html)、[源码固定版本](https://github.com/Roche/pyreadstat/tree/e6e23bc0021875f35fccc3c2707c3e5151c130bb)。文档显示 1.3.7，非本机安装版本。
- S3：[haven read_spss](https://haven.tidyverse.org/reference/read_spss.html)、[项目首页](https://haven.tidyverse.org/)。文档显示 2.5.5，非本机运行结果。
- S4：[GNU PSPP System File Format](https://www.gnu.org/software/pspp/pspp-dev/html_node/System-File-Format.html)。本次部分子页请求失败。
- S5：[IBM SPSS Statistics Data Files](https://www.ibm.com/docs/en/spss-statistics/32.0.0?topic=files-spss-statistics-data)。产品层数据/字典描述，不当作完整二进制规范。
- S6：[ReadStat SAV header](https://github.com/WizardMac/ReadStat/blob/4fbf1d8e516513dc06c7a73aab03b3daced87d4f/src/spss/readstat_sav.h)、[SAV reader](https://github.com/WizardMac/ReadStat/blob/4fbf1d8e516513dc06c7a73aab03b3daced87d4f/src/spss/readstat_sav_read.c)。
- S7：[ReadStat 传统压缩实现](https://github.com/WizardMac/ReadStat/blob/4fbf1d8e516513dc06c7a73aab03b3daced87d4f/src/spss/readstat_sav_compress.c)。
- S8：[GNU PSPP Very Long String Record](https://www.gnu.org/software/pspp/pspp-dev/html_node/Very-Long-String-Record.html)。
- S9：[Figshare 官方元数据 API](https://api.figshare.com/v2/articles/24792756)、[数据 DOI](https://doi.org/10.6084/m9.figshare.24792756.v1)。

网络检索不是不可变事实；报名、发布和对外“无同类”表述前应重新核查。原始检索证据保留失败，不以历史成功掩盖当前未验收状态。

## 8. PRD r0.2 的场景复审补充（2026-10-23）

本次补查了字符串系统缺失、标准 CSV、消费端 NA/类型推断和本地文件提交行为的一手资料，见 [PRD_REVIEW.md](PRD_REVIEW.md)。核心设计修正是：CSV 不使用私有反斜杠转义；按列类型表达数值系统缺失，字符串原样保留。独立审查及主代理 Node 实验发现 GBK/GB18030 下不同源字节可解成相同 Unicode；这不证明 SPSS 字符串匹配规则，却足以否定“严格解码就一定可逆”的假设。因此完整 bundle 始终带逐格原字节/数值位及缺失状态的权威 NDJSON，默认另有 CSV 视图，并提供独立消费示例和 bundle 校验；字符串匹配关系列入早期独立验证。目录输出采用排他创建与完成标志，不以目录改名冒充跨平台不覆盖事务。

这些是基于资料和使用流程推演的产品决定，没有新增真实用户反馈，也没有新增 SAV 解析或性能结果。r0.1 的检索结论仍按原日期和范围理解，不因 PRD 更新而自动变成重新完成全面查重。
