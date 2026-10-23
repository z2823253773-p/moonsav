# MoonSav v0.1 产品需求与设计

版本：r0.2，2026-10-23。**状态：用户已授权按本 PRD 在新对话实施；以下均为交付要求，不是已实现能力。**

授权记录（2026-10-23）：用户明确要求“按照这个PRD 开一个新的对话去完成项目”，并指定原对话负责验收、跟进及改进。无需重新选题或重复确认本设计；实施交接见 [IMPLEMENTATION_HANDOFF.md](IMPLEMENTATION_HANDOFF.md)。

本次收紧了用户定位，补足任务流程、失败恢复与消费者验收；撤销 r0.1 的 CSV 反斜杠私有转义，修正跨平台目录提交承诺。完整变更见 [PRD_REVIEW.md](PRD_REVIEW.md)，r0.1 原稿及原检查结果保留，不覆盖历史证据。

## 1. 目标、价值和验收定义

MoonSav 是 MoonBit 可调用的 SPSS `.sav` 读取库和离线 CLI。输入一个在支持矩阵内的 SAV 文件，输出有类型的数据和机器可读字典，准确保留变量名、类型、变量标签、值标签、源编码、系统及用户缺失语义和日期显示格式。遇到范围外或损坏输入，必须明确报错。

价值：让 MoonBit 程序直接消费带调查字典的数据，避免先转 CSV 后丢失字段含义或把缺失代码误当数值参与计算。成熟生态已有 ReadStat/pyreadstat/haven/PSPP，增量是 MoonBit 内的格式及语义实现、严格错误契约和可复现兼容性，不是发明新统计方法。重复性结论与限制见 [RESEARCH.md](RESEARCH.md)。

v0.1 完成必须同时满足：库和 CLI 可安装可运行；全部必需验收项通过；真实样例逐字段差异为零或有经审查的格式差异解释；坏输入与不支持输入有非零退出码；从干净目录可复现；README、示例、CI、依赖/许可与未覆盖清单齐全。字段缺失、乱码、缺失类型错误、数据与字典错配均为阻断发布的问题，不用更高通过率抵消。开发者复现不称作外部用户试用；官方报名、初审和验收另行记录。

## 2. 目标用户、任务和需求假设

### 2.1 谁最需要本项目

**首要用户**是需要在 MoonBit 程序中直接接入 SAV 的开发者，包括做研究工具、问卷工具或数据处理流程的开发者。其任务是取得有类型的数据及字典，并明确知道哪些值应排除、哪些标签只是解释。库是核心产品，CLI 同时是可独立使用的工具和库的验收入口。

**第二用户**是能使用命令行、需要检查或移交 SAV 数据的研究者/学生。他们需要少量清晰命令，不必理解物理记录、安装 SPSS 或配置 Python 科学计算环境。需要 Node 运行时仍是门槛，必须在安装前说明。

已经稳定使用 pyreadstat/haven、没有 MoonBit 集成需求的用户，不是本期重点争取的迁移对象。不能仅以“别的生态能做”证明其会换用 MoonSav。用户的数学及科研背景只是领域理解基础，尚无用户访谈、实际课题组需求、文件规模分布或使用频率证据。

### 2.2 三个任务场景

| 场景 | 用户起点与具体任务 | 最短使用流程 | 用户可判断的成功结果 | 最可能卡住的地方 |
| --- | --- | --- | --- | --- |
| U1 接入 MoonBit 工具 | 开发者有 SAV 字节和一个业务变量名，希望排除系统/用户缺失、用值标签展示类别 | 安装库 → inspect/read/scan → 通过变量索引与 Cell API 消费 | 不凭 99/空白猜缺失；没有标签的合法值仍保留；不调用 ReadStat/Python | 首次 import、后端编码适配、把数值标签误当字符串类型、回调保留了复用缓冲区 |
| U2 接手陌生调查文件 | 研究者收到 SAV，想确认列含义、编码、缺失、日期和是否可完整读取 | inspect 查看字典 → validate 扫完整文件 → 查 codebook 或 JSON | 明确区分“字典可读”与“全文件通过”；知道日期仍是原值；不需要打开任何个体记录 | 编码未声明、软件声明错误、文件截断、字典有大量变量或标签、unsupported 被误认作损坏 |
| U3 导出并移交数据 | 处理者要把数据交给使用 Python/R/普通 CSV 工具的协作者，协作者可能拿错元数据 | export 创建 bundle → check-bundle → 按配套示例读取 | 字符串/前导零不变；两类缺失可区分；数据与 metadata 不串包；标准 CSV 可正常打开 | 默认 NA 推断、数值列日期显示、标签替换原值、拆散文件、输出中断/目录冲突 |

三个场景都是拟验证任务，不写成已经发生的使用经历。CLI 本期不默认预览个体数据；库消费示例使用合成数据。原文件保留，用户随时可以回到成熟工具继续分析。

### 2.3 两个必须解释清楚的例子

- **合成问卷列 `score`**：底层数值 1、2、99、系统缺失，其中 99 的标签为“未回答”且被声明为用户缺失。值标签仍需显示，99 的数值仍需保留；`missing_kind` 应分别是 Present、Present、UserMissing、SystemMissing，不能统一变成空值后失去原因。
- **合成标识列 `subject_code`**：存储为字符串的 `0012`、`NA`、`\N` 与空白不能被自动变成数值或缺失。反过来，若 SAV 原本将 ID 存成数值 12、显示格式为 N4，MoonSav 只能保留 12 和 N4，不能编造原来有字符 `0012`。

### 2.4 需求假设与验证方式

| 尚未证明的假设 | 首次验证方式 | 若不成立如何处理 |
| --- | --- | --- |
| MoonBit 开发者需要直接读 SAV | 从全新消费者目录做 U1：只按文档集成、过滤缺失并显示标签，保存真实运行结果 | 修复 API/说明；不能用解析器内部测试代替消费者任务 |
| 命令行研究用户能理解产物 | 用 U2/U3 合成任务做开发者复现，确认输出说明足够；若有实际志愿用户再单独记录其反馈 | 优先改 codebook、错误提示和示例；不因此扩张成 GUI |
| 目标编码/大小覆盖常见文件 | 固定公开语料清单，报告生产者、编码、压缩、大小、行列与扩展分布 | 公开已验证边界；额外能力需单独决定，不把两份文件外推成整个 SPSS 生态 |

v0.1 不提供统计检验、科研结论或临床判断；不解释跳题逻辑、不推断 99 的含义、不代替 codebook 声明分析规则。没有真实用户时，任务验证只能称“开发者复现”。

### 2.5 本期投入顺序

P0 是格式与语义正确性、失败可解释、U1–U3 可完成、消费者端可复现。`inspect`、`validate`、`export`、`check-bundle`、codebook 及最小消费示例都是 P0。长字符串、两类缺失及严格编码保留原来的必需地位。完整导出以带类型的 NDJSON 为依据，标准 CSV 是配套通用视图；不要求用户猜两者哪个能证明原字节与缺失状态。

GUI、交互式预览、批量目录转换、列裁剪/行抽样、自动套用值标签、自动日期转换、清洗、统计分析和宽松修复均不加入本期。先把单文件闭环做好。参考项目的全部功能不是我们的待办清单。

## 3. 已选约束与实现方案

用户已固定 MoonBit 主实现、库+CLI、语义保留与证据验收。常规技术选择由实现者负责，以下为**实现者建议，待本设计整体确认**：

| 方案 | 取舍 | 处理 |
| --- | --- | --- |
| 全部基础设施也纯 MoonBit | 编码表、跨平台 I/O 等扩大首期验证面 | 保留长期可替换性，本期不重写全编码栈 |
| MoonBit 解析核心 + 薄 I/O/严格转码适配 | 可独立检验新增格式逻辑，复用成熟编码支持；需列明后端差异 | **推荐**；JS/Node CLI 为完整首发平台 |
| ReadStat FFI/子进程包装 | 更快取得成熟格式覆盖，但核心贡献变成绑定 | 不符合用户主实现要求，不采用 |

模块边界：`cursor/header` → `dictionary` → `compression` → `logical variables` → `semantics` → `export`。记录解析、长度/索引校验、字节码解码、逻辑列重组、值标签关联、缺失匹配和导出格式由 MoonBit 实现。适配层只处理文件、进程退出、SHA256、严格字符解码和输出流；不得承担 SAV 记录解析。bundle 的结构、类型、计数校验也由 MoonBit 实现；SHA256 运算可交给平台。

库核心不做网络请求和隐式文件读取。CLI 不自动下载输入。ReadStat/pyreadstat/PSPP 只在开发和验收环境；不进入发行包依赖。

## 4. v0.1 支持范围与兼容矩阵

“必需”均须有新鲜的真实命令证据后才可在 README 标为支持。

| 维度 | v0.1 目标 | 当前证明 |
| --- | --- | --- |
| SAV 容器 | `$FL2`；小端整数、同端 IEEE754 double | 未实现 |
| 压缩 | compression=0 未压缩；=1 传统字节码；文件头 bias 生效 | 未实现 |
| 数值 | double 原值及位表示；有限数与专用缺失哨兵 | 未实现 |
| 常规字符串 | 1–255 字节、八字节延续，保留逻辑宽度内的空格 | 未实现 |
| 超长字符串 | 256–32767 字节、扩展 14 重组；跨段多字节字符 | 未实现；必需风险门槛 |
| 名字与标签 | 短名、扩展 13 长名；变量标签；数值/字符串值标签；扩展 21 | 未实现 |
| 缺失 | 系统缺失；数值离散/范围/范围+离散；短字符串及扩展 22 用户缺失 | 未实现 |
| 编码 | UTF-8、Windows-1252、GBK、GB18030；具体 profile 须在 M1 固定，声明、版本、推导及覆盖均记录 | 仅 codec 层探测，已发现实现差异；无 SAV 编码兼容性证明 |
| 格式 | 原始 print/write 代码、宽度、小数位；日期类仍为数值 | 未实现 |
| 显示/测量元数据 | 扩展 11 中的测量水平、显示宽度、对齐方式按声明保留，不能从数值/字符串猜测 | 未实现 |
| 计数 | 已知/未知行数；扩展行数；零行、跨控制块；声明与实际核对 | 未实现 |
| 附加信息 | 文件标签、创建文本、权重变量引用；已识别文档/属性记录保留原始载荷并注明未解释 | 未实现 |
| 输入大端、IBM/VAX 浮点 | 检测后返回 UnsupportedLayout/UnsupportedFloat | 未实现 |
| `$FL3` / zlib / `.zsav` | 检测实际格式后 UnsupportedCompression；改名为 .sav 也拒绝 | 未实现 |
| `.por`、SAS、Stata、SPSS/PC+、加密文件 | 明确不支持 | 未实现检测 |
| 写 SAV、GUI、自动日期转换、统计分析 | 非本期 | 无 |

平台与后端：

| 后端/平台 | 本期交付等级 | 编码策略及验收 |
| --- | --- | --- |
| MoonBit JS 库 + Node CLI，macOS arm64 / Linux x64 | 必需完整支持 | UTF-8/Windows-1252/GBK/GB18030；Node 固定已验证版本与 ICU，严格转码 |
| Windows x64 Node CLI | 必需 CI 冒烟与错误退出/路径测试；真实格式测试跑同一语料 | 无本地 Windows 实机证明时标注 CI 验证，不能称实机试用 |
| wasm-gc/native 字节核心 | 必需编译及 UTF-8 核心向量；不承诺本地 CLI | 默认严格 UTF-8；其余编码须提供经验证的 Decoder 适配器，否则显式 UnsupportedEncoding |
| 浏览器 UI / WASI CLI / C ABI | 不支持 | 可作为后续迭代 |

不承诺任意版本 SPSS/所有 SAV 文件兼容。没有证据的工具链或平台不列为“已支持”。超长字符串、传统压缩和两类缺失是必需项，失败后不能不告知用户就删去。

## 5. 字典和单元格契约

每个逻辑变量至少包含：稳定序号、短名、有效长名、存储类型 Numeric/String、字节宽度、物理槽位范围、变量标签、值标签表引用、用户缺失定义、print/write 格式、测量/显示元数据（若存在）、原始相关记录位置。文件没声明的标签/测量水平用 null，空标签仍为空字符串，不能补写“默认已声明”。名字不自动改写或去重；冲突、悬空索引、非法延续与矛盾长名映射报 InvalidDictionary。保留大小写，按格式规定的无大小写名字规则检查歧义；对外优先用稳定序号，不让两个别名静默遮蔽彼此。

单元格区分：

```text
Number(value: Double, ieee754_hex: String, missing: Present | UserMissing)
String(value: String, logical_bytes: Bytes, missing: Present | UserMissing)
SystemMissing(raw_bits: UInt64)
```

数值位表示用于区分负零等边界，不从标签反推类型。Number 的 UserMissing 仍携带原始数值；字符串也保留原字节。**SystemMissing 只允许出现在数值变量**；字符串空白不是系统缺失，符合 [IBM 字符串缺失说明](https://www.ibm.com/docs/en/spss-statistics/30.0.0?topic=data-missing-values-string-variable)。值标签是映射表，不替换数据值；多个变量共享标签表仍保留各自引用。未标注的值合法保留；相同文字可以对应多个代码，但同一个代码的相互矛盾标签不能覆盖。

对外提供 `Cell::missing_kind()`、`Cell::is_missing()` 和 `Variable::value_label_for(cell)` 等价能力，开发者无需重写缺失判断或标签匹配。`is_missing` 覆盖两类缺失；它不删除数据。metadata 中的数字代码、缺失端点也需可保留负零/精确 double，规范形式为带 `decimal` 和 `ieee754_hex` 的 NumericAtom；不能只保留 JSON 对象键或宿主默认数值序列化结果。

范围缺失用带语义的端点 `Finite/Lowest/Highest`，不能把 LOWEST/HIGHEST 当普通数值损坏。字符串缺失和字符串值标签匹配必须遵循已核实的格式规则（含宽度、填充及比较关系），不用解码后随意 trim 猜测。原字节/宽度始终保留；M1/M2 须以独立工具和规范固定“按源字节比较还是按编码等价关系比较”，把采用规则记为 `string_matching_policy`，包含重复编码映射用例。若无法确定某输入的正确语义，显式 UnsupportedStringSemantics，不能选择更容易实现的一种后报告兼容。空白字符串不是系统缺失。

权重变量引用是字典信息，读取/导出不自动加权、过滤、排序或去重。所有原始 cases 依次输出，合成案例中相同行也不能合并。标签“未回答”本身不等于用户缺失声明；没有声明的 99 必须仍为 Present。

为保留信息，数据字符串默认仅去除**超出逻辑字节宽度**的物理填充，逻辑宽度内尾部空格保留；不提供默认 `rstrip`。对照工具若裁尾，比较其规范化文本并同时核对原始宽度及重建字节，不把不同展示策略误报或掩盖为一致。字符串分段后才解码，避免中文跨八字节单元被误判。

## 6. 编码与日期策略

编码选择顺序：显式 `--encoding`/Options → 扩展 20 → 明确的机器字符代码映射 → EncodingRequired。保留所有声明及冲突信息；两个可信声明冲突且无覆盖时 EncodingConflict。ASCII 字节“看起来正常”不能替代整文件编码声明。

允许覆盖必须记录 `declared`、`effective`、`selection_source=override`，返回结构化提示。Node `TextDecoder(..., {fatal:true, ignoreBOM:true})` 是待验证的适配候选，**并非已经接受为所有目标代码页的最终实现**；必须通过下面的编码 profile 门槛才能采用。按选择的完整字段解码，不允许替换错误、BOM 隐式吞字或退回另一编码。合法输入本来含 U+FFFD 时允许，不能通过“输出是否含 U+FFFD”检测解码错误。

严格解码只能发现非法序列，**不能保证声明/覆盖的编码一定正确**：同一字节可能在另一编码下合法但显示错误。字典可解码后以标签供用户核对，不能输出“已自动识别正确编码”。覆盖产生 `EncodingOverride` 提示，声明矛盾仍原样保留。对于旧文件的泛化 ASCII/EBCDIC 标志，先按格式区分“编码家族提示”与“明确代码页”，不能把泛化提示与 UTF-8 声明误报为两个可信声明冲突。

SPSS 的代码页声明与 WHATWG 名称建立小型显式白名单；不直接采用 WHATWG 的所有别名。ISO-8859-1 不冒充 Windows-1252；不在白名单则报错。GBK/GB18030 的真实映射必须用 Python codec/PSPP 和边界向量验证，差异保留；不能把平台支持名称当格式兼容证明。具体 Node/ICU 和编码映射写入元数据。

**早期硬门槛：编码 profile。** 本次实测 Node 与 Python 的 GB18030 对 `A3A0` 分别输出 U+3000 与 U+E5E5，其他字节也有接受/拒绝差异。这不能直接证明谁符合原 SPSS 文件；不同标准版本、代码页及实现必须区分。M1 固定每种支持编码的规范/代码页版本、别名白名单、解码器版本和差异向量，与 PSPP/ReadStat及一手映射资料交叉验证。Node 候选不符合目标 profile 就替换适配器，不能以保留 base64 为由接受错误文本，也不能把 Python codec 当无条件真值。无法确定的变体显式 UnsupportedEncodingVariant，保留原字节和明确解释；编码矩阵必须写明变体边界，不能对外笼统声称所有 GB18030 文件均已兼容。适配选择属于实现者工作，不要求用户替我们选择底层编码标准。

日期/时间变量保留底层 double、原始格式和缺失。v0.1 不做 epoch 换算、日历/时区推断或自动 ISO 日期导出。API `DatePolicy::Raw` 是唯一支持策略。以后若做转换，必须另立精度、超范围、历法与无时区契约。

## 7. API 任务

以下为设计签名，**不是已能编译的 MoonBit 示例**；具体错误类型语法由 M1 固定，语义不可擅改。

```text
inspect_bytes(input: Bytes, options: Options) -> Result[Dictionary, SavError]
read_bytes(input: Bytes, options: Options) -> Result[Dataset, SavError]
scan_bytes(input: Bytes, options: Options,
           on_dictionary: Dictionary -> Unit,
           on_row: Array[Cell] -> ScanControl) -> Result[ScanSummary, SavError]
```

`Options` 包含显式 limits、可选 encoding_override、后端 Decoder、严格扩展策略。`inspect_bytes` 只验证头/字典，不声称数据区完整；输出 `validation_scope=dictionary_only`。`read_bytes` 收集小型数据，受额外 cells/retained_bytes 预算限制。`scan_bytes` 按行消费、背压同步，输入仍为受限内存字节，**不称为流式文件输入**。

回调得到的行/单元格是不可变且可安全保留的值，后续行不得修改前一行内容；支持的所有后端均验证此约定。库预算只约束库自身，调用者自行缓存所有行的额外内存由调用者负责。回调错误返回独立的 ConsumerFailed，不伪装成坏 SAV；回调 Stop 返回 `completed=false` 和实际行数，不能标为全文件通过。行数/变量序号在机器接口中均为零基且有字段说明。

CLI `validate` 必须扫到结束；按列报告 Present/UserMissing/SystemMissing 三种计数，每列合计等于实际 case 数，不把列缺失次数加成“缺失人数”。库不打印、不终止进程、不写磁盘。Decoder 必须在失败时返回结构化错误，不接受有损文本作为成功。首次消费示例必须覆盖缺失过滤、没有标签的值、字符串 ID 和安全保留两行数据。

## 8. CLI、输入输出及 CSV 契约

设计命令（尚未实现）：

```sh
moonsav inspect input.sav --json
moonsav inspect input.sav --variable score
moonsav validate input.sav --json
moonsav export input.sav --out output_bundle
moonsav export input.sav --out output_bundle --encoding gb18030
moonsav export input.sav --out output_bundle --format ndjson
moonsav check-bundle output_bundle --json
moonsav validate input.sav --json --fail-on-warning
moonsav --help
moonsav --version
```

### 8.1 用户看到什么

无参数或参数错误时显示短用法和退出码 2，`--help` 为 0。默认输出可读文本；`--json` 是稳定机器报告，不能让管道解析带颜色的说明文字。`inspect --variable` 按完整有效变量名或短名查找，没找到明确报错，不模糊匹配/自动选近似列。

| 命令 | 用户可见结果 | 成功并不代表什么 |
| --- | --- | --- |
| inspect | 文件格式、选定编码与来源、变量数、**声明**行数或 unknown、支持判断、字典摘要、提示；可查看单列详情 | 数据区未扫描，actual_rows=null，不能称“全文件通过” |
| validate | 全文件实际行列数、逐列缺失计数、解释范围、提示、耗时及限制 | 不证明课题设计或数据本身真实，也不纠正错误编码声明 |
| export | 成功 bundle 路径、输出格式、实际行列、提示数量及下一条 check-bundle 命令 | 不替用户决定缺失排除、统计或日期转换 |
| check-bundle | 配套文件版本/哈希/结构/类型/计数校验与摘要 | 不与 SAV 重做兼容性比较，也不是签名/可信来源认证 |

人类摘要默认最多显示 20 个变量、每变量 10 个值标签，并明确标注“显示 m / 总 n”；这只是显示截断。`inspect --json` 输出完整字典（受预算约束），`--variable` 提供单列完整信息。完整导出和 validate 不允许偷偷减行减列。CLI 不默认打印单元格内容；没有“匿名预览”承诺。

JSON 报告包含 `report_version`、`command`、`status`、`validation_scope`、`declared_rows`、`actual_rows`、`logical_variables`、`warnings`、`error`。失败时 command/validation_scope/status/error 必须存在，未知计数为 null，不填 0。`validation_scope=full` 指完整扫描本期支持的数据/字典契约，不能被写成“所有 SPSS 附加语义均已解释”；`uninterpreted_metadata` 始终显式列出。JSON 成功报告 stdout 一条，错误报告 stderr 一条；机器模式不用 stderr 再复制一份完整 warnings，避免重复解析。人类模式可在 stderr 展示提示。不把有提示的成功伪称无提示。

`--version` 至少给出产品/构建版本、MoonBit 工具链、Node/ICU、支持编码和 schema 主版本。跨工具链的字节核心与完整 Node CLI 的能力在帮助中分别列明。

### 8.2 配套产物

默认 `--format csv` bundle 包含 **`data.ndjson`（有类型的权威数据）与 `data.csv`（标准通用视图）**，另有 `metadata.json`、`codebook.md`、`manifest.json`。`--format ndjson` 只省略 CSV，其余一致；不提供默默丢掉权威数据的“纯 CSV 完整导出”。两份数据由一次 MoonBit 扫描的同一行生成，不重复读取源文件。这是复用原有两种输出格式，不新增第三种私有转义格式。

选择依据：本机 Node 严格 GBK/GB18030 解码实验中，`A1A1` 和 `A3A0` 都成为 U+3000。**这只证明解码可能非单射，不证明 SPSS 的比较语义**。仅 CSV 文本+列宽+整列字典不能普遍证明每格原字节、缺失判定或标签键；因此这些信息必须在逐格权威记录内保留，不寄望于反向编码。代价是默认包更大，全部产物都计入预算；只要权威数据写不下就整体失败，不悄悄只留 CSV。

codebook 是给人读的列字典：变量名/标签、真实存储类型、字节宽度、值标签、缺失定义、测量信息和日期/显示策略，并说明正确读取方式与 NDJSON/CSV 层次。它不包含样本行，也不补写标签含义；名字/标签中的 Markdown 特殊字符按文本转义。完整标签表以 metadata 为准，codebook 若按显示预算截断必须标记。

manifest 明确列出所有数据文件、metadata、codebook 的 SHA256/大小、bundle profile（csv_with_canonical / ndjson）、schema 版本、精确行列数、输入 SHA256/大小及策略。**不对自身哈希**；输入解析与输入哈希使用同一份实际读取字节。默认不保存输入绝对路径、用户名或文件名。复制数据而漏掉任一必需配套文件就不再承诺标签/缺失语义完整。

`check-bundle` 在同一预算下检查完整文件集合、支持的 schema 主版本、SHA256/字节数、表头/变量顺序、每行字段数和实际记录数。逐行检查 NDJSON 的序号、cell kind、数值位/十进制与数值缺失声明/系统哨兵的一致性、字符串原字节/声明编码 profile 解码文本，以及按 string_matching_policy 得到的字符串缺失和标签匹配；若有 CSV，与同一行 NDJSON 的可见值逐格核对。不得根据 CSV 反推不可逆字节；两流只保留有限行缓冲，避免全量收集。CSV 多行字段按 CSV 解析计行，不能数换行符。

未知主版本返回 UnsupportedSchema；缺件、字典被改且哈希未更新、错配文件、损坏行、未提交状态均非零。它只读，不修补/补签 manifest。只接受白名单文件名，拒绝指向 bundle 外部的路径或文件符号链接。额外普通文件不作为数据参与校验，明确标为未验证；INCOMPLETE 绝不能忽略。若有人同时一致地修改数据/字典/manifest，本校验不能证明原件未被改；真实性和发布者身份不在其保证内。

### 8.3 标准 CSV 与语义恢复

**合成设计例子，非真实命令输出**：`id` 是字符串，`group` 是数值（标签“组别”，1=“A组”、9=“未回答”，9 为用户缺失），`note` 为逻辑宽度 2 字节的字符串。

```csv
id,group,note
0012,9,ok
0013,"",\N
```

CSV 使用 UTF-8 无 BOM、逗号、CRLF、双引号引述/转义，遵循 [RFC 4180 的常用约定](https://www.rfc-editor.org/rfc/rfc4180)。**不定义私有反斜杠转义或全局缺失 token**。`\N`、`NA`、路径和反斜杠原样保留。

系统缺失只存在于 numeric 列，用 CSV 空字段表达；writer 将该空字段固定输出为 `""`，避免单列全缺失行成为空行。numeric 列没有其他“空值”，可依据 metadata 的类型无歧义识别 SystemMissing。string 列的空字段只解释为字符串，不升级成系统缺失；来自 SAV 的固定宽度全空白则导出为相应逻辑宽度的空格，而不是主动变成零长字段。用户缺失状态和需要源字节的标签匹配以 NDJSON 及声明为准；CSV 单独不能提供普遍保证。逻辑宽度内空格继续保留，不靠引号判断缺失。遇到标准文本交换无法表示的 NUL，CSV profile 整体返回 ExportRepresentationError，建议重新导出 NDJSON profile；不替换字符后成功。

项目交付一个可运行的 **Python 标准库读取示例**：先用 check-bundle 校验；用 `json` 读权威 NDJSON/metadata 获得值、字节和 missing-kind，并演示如何跳过两类缺失；若有 CSV，再用 `csv.reader`（`newline=''`、UTF-8）逐行核对展示值，保留字符串 ID、NA 文本及尾空格。它是跨语言消费示例，不是产品运行依赖。若给 pandas 例子，必须控制 `dtype`、默认 NA 推断和空行处理，且不能把 CSV 的字符串等价推断当逐格语义保证。[pandas 官方参数说明](https://pandas.pydata.org/docs/reference/api/pandas.read_csv.html)

普通电子表格双击打开可能自动改前导零/日期或解释公式。默认导出坚持原值，不悄悄加单引号或修改公式样字符串；codebook 提示以文本方式导入或使用配套示例。本期不提供“Excel 无损/安全导出”模式。

数值不替换为标签；用户缺失值原样导出，通过 metadata 的定义重建 missing-kind。double 用可回读的最短十进制表示，负零保留；不使用系统缺失哨兵冒充普通数值。非哨兵 NaN/Infinity 在 v0.1 数值契约外返回 UnsupportedNumeric，而非输出非法 JSON/CSV。

元数据示意（省略其他必需字段，最终须有版本化 JSON Schema）：

```json
{
  "schema_version": "moonsav.metadata/1",
  "validation_scope": "full",
  "encoding": {"declared": "UTF-8", "effective": "utf-8", "selection_source": "record20"},
  "csv": {"numeric_system_missing": "empty_field", "string_escape": "csv_quotes_only", "date_policy": "raw"},
  "variables": [{
    "index": 1, "name": "group", "short_name": "GROUP", "type": "numeric",
    "label": "组别",
    "value_labels": [
      {"value": {"type": "numeric", "decimal": "1", "ieee754_hex": "3ff0000000000000"}, "label": "A组"},
      {"value": {"type": "numeric", "decimal": "9", "ieee754_hex": "4022000000000000"}, "label": "未回答"}
    ],
    "user_missing": {"kind": "discrete", "values": [
      {"type": "numeric", "decimal": "9", "ieee754_hex": "4022000000000000"}
    ]},
    "print_format": {"raw": 329216, "code": 5, "width": 6, "decimals": 0}
  }]
}
```

标签表用数组和显式类型，不能用 JSON 对象键强制把数值都转字符串。字符串标签键和字符串用户缺失定义必须同时保留逻辑字节 base64、声明宽度及解码文本，不只留 Unicode 字符串；匹配用所声明且已验证的 string_matching_policy。metadata 必须保存原始宽度、字典来源位置、格式、缺失规则、文件级缺失哨兵与表示、未解释附加记录清单；manifest 与 metadata 的哈希绑定在同一 bundle 中。已识别但未解释附加记录的原始载荷可使用 base64，受字典预算约束；未知记录仍按第 9 节默认拒绝。

NDJSON 为逐行权威数据，每行含零基 row 和按字典顺序的 cells；每个单元带 kind/missing，数值附规范十进制字符串与 IEEE754 hex（系统缺失也留原始 bits）、字符串附文本与逻辑字节 base64。hex 统一为 16 位小写、按位值高位在前（与文件大小端无关）；同一单元多个表示不一致必须报错。NDJSON 保留逻辑值的位/字节以支持语义和诊断，**仍不承诺 SAV 容器记录/填充逐字节保存或写回**。CSV 单独是通用文本视图，完整 bundle 才承诺本 PRD 的值/类型/标签/缺失/格式语义。

与上面 CSV 第一行对应的 NDJSON 示意（不是实际产物，完整 schema 仍需在实现阶段落地）：

```json
{"row":0,"cells":[{"kind":"string","text":"0012","logical_bytes_base64":"MDAxMg==","missing":"present"},{"kind":"numeric","decimal":"9","ieee754_hex":"4022000000000000","missing":"user"},{"kind":"string","text":"ok","logical_bytes_base64":"b2s=","missing":"present"}]}
```

系统缺失单元使用 `kind=numeric, missing=system`，保留 ieee754_hex，decimal=null；Present/UserMissing 的 numeric 不能为 null。所有字段组合在 schema 中明确约束，不能让 consumer 猜 token 含义。

### 8.4 输出事务、并发与中断恢复

v0.1 仅接受本地普通文件；不读 stdin/管道/URL/压缩包，不写数据到 stdout。输入只读打开，读取时限长；读前/读后检测到文件变化则 InputChanged，不把一份字节的哈希配上另一份内容。stat 预检不能代替实际读取上限。

为避免“检查后改名”的竞态，不依赖跨平台目录 rename 能实现不覆盖提交。流程是：完成字典/支持性检查 → **排他创建新输出目录**（已存在即 OutputExists）→ 创建 `INCOMPLETE` → 写各文件并校验/关闭 → 最后发布 manifest → 移除 INCOMPLETE 作为提交点。并行两次导出到同一路径只能一次取得目录，不使用覆盖或合并。输出目录在提交前可能可见，但没有有效完成标志，消费者必须先 check-bundle。权限采用 POSIX 目录 0700/文件 0600；Windows 保留宿主 ACL 行为并如实说明。

普通错误发生在提交前时清理本次能确认属于自身的新产物，清理过程中保留 INCOMPLETE，直到其他产物已移除；清理失败、SIGKILL 或断电可能留下 INCOMPLETE 目录，明确报告“未完成，换新输出目录重试”。不自动接管或删除上次运行的目录，不提供强制覆盖/续传。提交后报告输出失败或进程被杀，bundle 可能已经完整；用户通过 check-bundle 判定，不因没收到成功文字就删掉已提交数据。发布前验证失败/中断不得留下可误认作完成的产物；不承诺断电后的数据库级持久事务。

### 8.5 安装与首次成功路径

交付可本地安装的 Node 包归档及 SHA256，含预编译 MoonBit JS 与 `moonsav` 启动入口，不要求 CLI 使用者另装 MoonBit/Python/C 编译器。明确已验证的 Node 版本；声明范围内版本须跑相同安装冒烟，否则只承诺锁定版本。取得包与 Node 后，CLI 的 inspect/validate/export/check-bundle 可离线完成；U1 库集成另需 MoonBit 工具链，Python 消费示例另需 Python（只有标准库）。不把开发者工具需求隐藏为“零依赖”。默认没有联网、遥测、账号或自动更新步骤。

README 的第一条路径为：安装/解包 → `--version` → 对随包的无个人信息合成样例 inspect → validate → export → check-bundle → 读取示例。文档中的成功输出必须从最终构建运行捕获，不能使用本 PRD 的示意结果。MoonBit 开发者另有一个全新消费者目录的最小导入示例；库安装和 CLI 安装分别验证。

## 9. 错误、扩展与资源限制

`SavError` 至少带 code、message、可用时的零基文件 byte_offset、record/subtype、变量/行索引、非敏感结构实际值及上限、`suggested_action` 和 `output_state`（not_created/incomplete/committed/unknown）。消息不默认打印原始单元格、标签或完整本地路径。CLI 错误 JSON 到 stderr，成功内容到 stdout；不夹杂日志。退出码：0 成功、2 参数、3 I/O/目的地冲突/输入变化、4 损坏格式或 bundle 完整性失败、5 不支持/编码要求/无法导出表示、6 资源超限、7 提示被严格策略拒绝、70 内部错误。提交前内部错误不得形成有效 bundle；提交后故障按 8.4 明示恢复方法。

主要 code：InvalidMagic、Truncated、InvalidLength、InvalidDictionary、InvalidCompression、CaseCountMismatch、UnsupportedCompression、UnsupportedLayout、UnsupportedFloat、UnsupportedEncoding、UnsupportedEncodingVariant、EncodingRequired、EncodingConflict、InvalidEncoding、UnsupportedExtension、UnsupportedStringSemantics、UnsupportedNumeric、UnsupportedSchema、ExportRepresentationError、ResourceLimit、Io、InputChanged、OutputExists、IncompleteBundle、IntegrityMismatch、WarningRejected、ConsumerFailed。具体错误变体在 M1 冻结，不能用一条泛化 ParseError 代替分类。

结构化提示至少包含稳定 warning_code、影响范围与处理建议。`EncodingOverride`、`UninterpretedMetadata`、`UnverifiedExtraFile`、日期仅输出原值等已定义提示能正常完成，默认返回 0 并令 status=passed_with_warnings；无提示则 passed。它们不能承载字节错误、字段丢失或声明矛盾。`--fail-on-warning` 在 inspect/validate/export/check-bundle 均生效，出现任一当前或继承的提示返回 7；export 必须在提交前据此终止。未知主版本一律拒绝，已知版本内明确允许的附加字段不得改变已有含义。

### 9.1 用户遇到问题后的下一步

| 用户看到的问题 | 必须给出的区分/建议 | 禁止的隐式操作 |
| --- | --- | --- |
| 文件扩展名是 .sav 却不支持 | 显示检测到的格式/压缩及不支持点；建议用成熟工具另存为已支持格式，保留原件 | 改后缀后宣称转换；读出部分列当成功 |
| EncodingRequired / InvalidEncoding | 说明缺少可靠声明或字节非法，建议核对提供方编码，再显式覆盖并重新验证 | 猜 GBK/UTF-8、替换乱码；声称能自动证明编码正确 |
| 字典可读、数据区截断 | 显示 validation_scope 和已读/声明行数；建议重新取得完整文件 | 静默接受前 N 行、给产物写完整标志 |
| CSV 看起来标签/日期“不见了” | 指向 codebook/metadata，说明值标签不替换值、日期保持数值 | 自动映射标签、自动转换时区或隐藏原始数值 |
| ResourceLimit | 显示触发项、预算及已处理数量；可降低需求或使用其他工具，本期不承诺超限文件 | 自动抽样、只导出能放下的部分 |
| 输出目录已存在或上次中断 | 不改旧目录；建议新目录重试；已有 manifest 则先 check-bundle | 自动覆盖、自动删除或接续旧文件 |
| 移交 bundle 报 IntegrityMismatch | 明示缺件/哈希/结构不一致，重新完整移交或从原 SAV 导出 | 修改 manifest 让校验通过 |

对已支持特征和范围外特征混合的文件采取整个任务明确拒绝，不提供默认“尽量读”。库受控停止和人类摘要裁显示数量是显式的部分结果，不得成为 export/validate 的成功捷径。

已识别且明确不改变必需数据语义的文档/属性扩展可按原始载荷保留并出具 `uninterpreted_metadata` 清单；它们不算已解释语义。未知 type 7 默认 UnsupportedExtension；未知无长度记录一律拒绝。MR 集合等高层含义不在承诺范围，不静默抛弃；相关记录若尚无可靠边界解析则报错。不得为“兼容率”跳过未知记录，不能给影响列布局/编码/标签/缺失的扩展开静默放行。

建议默认预算（实现者选择，M1/M2 可根据实测收紧但须记录）：

| 项目 | 默认上限 | 执行点 |
| --- | --- | --- |
| 输入 | 256 MiB | CLI 读取前 stat，并在实际读取时再限；库入口检查 bytes |
| 字典总原始/解码记账 | 各 64 MiB | 每条记录/标签分配前 |
| 逻辑变量 / 物理八字节单元 | 100000 / 1000000 | 解析与分配前 |
| 逻辑字符串宽度 | 32767 字节 | 变量及分段重组前 |
| 单条标签/扩展载荷 | 1 MiB / 16 MiB | 声明长度校验后、分配前 |
| 单行解压宽度 | 8 MiB | header 与字典一致性检查 |
| 完整扫描行数 | 1000000 | 每行前；未知行数也适用 |
| 收集模式 | 5000000 单元；128 MiB 计费载荷 | 数量和字符串/数值载荷双重预算 |
| 导出数据总字节 | 512 MiB | 每次写前，CSV/JSON 转义后计数 |

所有计数乘加采用检查溢出；禁止先做 `size*count` 溢出再校验。资源预算不能放宽格式本身的合法长度。处理数量等于预算且恰好到 EOF 可以成功，继续处理会超预算才报错，不裁剪为成功。v0.1 库 Options 可降低预算，CLI 提供 `--max-input-bytes`、`--max-rows`、`--max-output-bytes`，只能下调到正数；不能通过参数提升编译的安全上限。若真实需求要求更高上限，测量后另行调整产品版本。

输入预算覆盖 inspect/validate/export，输出总字节预算覆盖所有 bundle 文件（含 JSON/base64 膨胀和 codebook，不只数据），check-bundle 同样限制总文件大小/行数/记录载荷。停止条件还覆盖只有 no-op 的恶意压缩流（输入预算、单次扫描步数预算按输入长度推导）。不以“流式输出”为由声称能处理任意大小输入。

以上是应用记账上限，不是进程 RSS 承诺；对象/运行时开销单独实测。CI 对损坏语料设置每文件 10 秒、独立进程和内存监测，明确它与解析器内预算不同。取消/中断按 8.4 区分提交前后，不产生假完成状态。

## 10. 可执行验收矩阵

下面是**未来必须落地的命令接口**，现在脚本尚不存在。`python tools/verify.py --case ID --output DIR` 应执行生成/读取/对比及退出检查并写结果 JSON；`--all --require-public --require-pspp` 为正式验收，不允许 skip 被统计为 pass。单独保存 setup/依赖错误和预期解析拒绝。

| ID | 输入与执行 | 可观察通过条件 |
| --- | --- | --- |
| AC01 最高风险闭环 | pyreadstat 固定版本生成 3+ 行，含变量/值标签、数值、小数、字符串、系统及用户缺失；none 与 row-compress 各一份；MoonBit 读后对照 | 所有逻辑字段、字典映射、缺失类型逐字段一致，退出 0；oracle 设置不预转换数据 |
| AC02 独立家族 | PSPP 生成或读取同一语义场景，用 MoonSav/PSPP/ReadStat 对照 | 两个工具家族有版本及命令证据；差异逐条解释；不可把 haven+pyreadstat 充数 |
| AC03 公开文件 | 至少 2 个来源不同、有许可的实际 SAV，其中 1 个研究/调查文件 | 哈希/归属/许可/来源保存，实际全量行列与支持字段比较，不只读头；无识别信息泄露 |
| AC04 压缩 | 0/1、253 literal、254 spaces、255 sysmis、跨行/控制块、非默认 bias、未知行数、零行 | 对照一致；252 提前结束、声明计数冲突、截断均明确拒绝 |
| AC05 字符串 | 1/7/8/9/255/256/504/505/32767 字节，中文跨单元和跨段；长名、扩展 21/22 | 重组字节和文本一致，无静默裁尾、乱码或列数膨胀 |
| AC06 编码 | 四种目标编码，数据/标签/变量名；声明缺失、冲突、显式覆盖、真实 U+FFFD、坏字节与断尾 | 每种承诺编码有合法正例对照通过；范围外明确拒绝不能充当该编码正例；非法序列 InvalidEncoding，无静默替换；后端矩阵符合契约 |
| AC07 缺失/数值 | 正常极值/负零、系统哨兵、离散、闭区间、LOWEST/HIGHEST、范围+单值、短长字符串缺失、空白；有标签但无缺失声明的 99；重复编码映射 | raw 与 missing-kind 分开；99 不靠标签猜缺失；字符串没有 SystemMissing；负零不丢；匹配规则有规范/独立工具证据，差异不隐藏；非哨兵 NaN/Inf 明确拒绝 |
| AC08 导出语义 | 两种 profile，0012/NA/\N/反斜杠/空白/逗号/引号/多行/中文/尾空格、单列全系统缺失、零行、NUL、不同字节解成相同文本，含日期/显示格式 | 默认同时有 CSV 和权威 NDJSON；无私有转义；独立示例从权威记录恢复逐格语义；空行不漏；NUL 的 CSV profile 拒绝而 NDJSON profile 保留；原字节/状态不因文本等同丢失 |
| AC09 损坏/范围外 | 每关键记录截断、负/极大长度、错误索引、重叠映射、坏 continuation；大端、FL3、POR、未知扩展 | 期望 code+退出码；无越界/挂起/有效产物；未支持与损坏不混报 |
| AC10 资源 | 每种限制的界内、等于、超 1；乘法溢出声明、小压缩输入巨大解压、no-op 流 | 在分配/写入前拒绝；非零；不通过悄悄减行满足预算 |
| AC11 文件行为 | 只读输入、输入变化、输出已存在、两进程同路径、无权限、磁盘写失败、空格/中文路径、各提交阶段中断 | 输入 SHA 不变；并发不覆盖；提交前失败/INCOMPLETE 不被 checker 接受；提交后能校验恢复；输出状态及退出码正确 |
| AC12 包与后端 | 全新消费者目录安装本地打包产物，调用公开 API；固定工具链的 JS/native/wasm-gc 及平台 CI | 不借开发目录导入；示例可编译执行；标注本机/CI/未测差别 |
| AC13 可复现审查 | 新检出运行固定依赖与同一验收入口；人工查看差异及坏输入行为 | SHA、dirty、命令、exit、版本、输入输出哈希、时间/资源、失败及未覆盖齐全；无只引用历史绿灯 |
| AC14 U1 消费者任务 | 全新 MoonBit 消费者仅依 README，读合成 score/subject_code，过滤两类缺失、查标签、保留两行，测试 Stop/回调失败 | 输出与独立源数据一致；没有回调缓冲复用污染；缺失/未标签值/ID 正确；部分扫描明确 completed=false |
| AC15 U2 理解与失败恢复 | 只用 CLI 做字典检查、单列查询、完整验证、错误编码/截断/限制触发后重试；20+变量/10+标签 | 声明和实际计数不混；摘要截断有标记；JSON完整；错误有具体可行建议；默认不打印个体值 |
| AC16 U3 移交与错配 | 两种完整 profile、交换另一文件的 metadata、删 canonical NDJSON、改字典/行/计数、CSV与NDJSON不一致、未知 schema、INCOMPLETE、附加文件 | 正常配套通过；缺权威数据/错配失败；规范表示和声明匹配规则校验；多行记录数正确；checker 不修复 manifest，也不声称签名认证 |
| AC17 安装与机器模式 | 从归档在未装 MoonBit/Python 的环境启动 CLI；离线运行首次路径；失败/提示/严格提示三类结果 | 随包样例可运行；JSON schema/通道稳定、无额外联网；不同提示不伪装成解析失败；严格 export 不提交 |
| AC18 规模和可重复输出 | 固定种子生成 10000×20 的代表性混合数据，两种压缩；完整 validate/export/check-bundle；每种运行 3 次 | 在 M1 声明的参考机上每任务中位耗时≤30秒、峰值RSS≤512MiB；记录实际值；相同输入/构建/选项的数据与元数据字节相同，运行耗时不参与语义哈希 |

对照层次：生成器源数据 → oracle 读回 → MoonSav 读出 → 独立导出反读。禁止 MoonSav 自己同时生成期望结果。压缩整数和有效数值应精确比较；double 以原始 bits/可回读十进制核对，确有工具规范化差异必须单列，不能对所有数字套宽松误差吞掉缺陷。

AC18 是本期选择的验收目标，尚无性能证明；不外推至 256 MiB 上限或所有硬件。不用 CI 共享机器波动代替参考机测量。若原型达不到，先定位开销并修复；不能未经记录把目标改成历史实测值。运行时间/路径等非语义信息放报告，稳定元数据不嵌入当前时间。声明工具链/平台差异时分别留基线。

语料清单在 M1 冻结来源与期望类别；后续新增失败样本不得移出统计而不留记录。结果至少分 supported_pass、supported_fail、expected_rejection、unexpected_result、not_run 五类；拒绝了范围外文件不算兼容成功，跳过不算通过。两份公共文件都必须实际完整读取通过才能满足 AC03；光下载、仅读头、两份均被拒绝或给文件打 skip 都不满足。

最高风险原型除了 AC01，还必须演示 U1 最小消费者、标准库读权威 NDJSON 与 CSV 配套核对的最短闭环，并验证字符串匹配关系；否则容易得到“能解析、用户仍接不上”的原型。U2/U3 在 M3 做完整任务复现。至少一个独立审查者从新目录复现用户路径；若审查者是代理，按事实标注，不叫外部用户访谈。

## 11. 证据、里程碑和交付

每轮 `evidence/<run-id>/run.json` 至少含当前 git SHA/分支、dirty 和 diff 摘要、UTC 时间、命令参数数组、工作目录（公开包去除个人绝对路径）、工具版本、依赖锁定、平台、退出码、stdout/stderr、输入/输出哈希、比较摘要、失败/未覆盖/跳过理由。失败产物保留在开发证据内；公开证据只使用合法合成/公共数据并先扫描。

| 阶段 | 交付及门槛 | 当前状态 |
| --- | --- | --- |
| M0 研究与设计 | RESEARCH/PRD、查重边界、首轮 builder 审查、用户确认设计 | 本轮文档编写；待确认 |
| M1 环境与高风险原型 | 固定工具链/验证依赖、语料清单、参考机和编码 profile，AC01 + U1 最小调用 + NDJSON/CSV 独立消费 + 字符串匹配验证 | 未开始 |
| M2 核心实现 | 两种压缩、字典/字符串/缺失、编码和上限；AC04–07/09/10 | 未开始 |
| M3 产品化 | API、CLI/bundle/checker/codebook/schema、示例、安装与 U1–U3；AC08/11/12/14–18 | 未开始 |
| M4 兼容与审查 | PSPP、公开真实文件、破损语料、全部验收、独立代码审查 | 未开始 |
| M5 交付与赛事 | README、CI、可安装归档及哈希、完整失败/未测列表；发布/报名按授权和届时规则 | 未开始 |

设计通过后才形成 `docs/PLAN.md`，按依赖拆成可执行任务与准确命令。本节是产品里程碑，不冒充已经存在的实现计划。日期由实际进展及十一月正式通知确定，不虚构工作量天数和截止日。

最终至少交付 MoonBit 模块、Node CLI 包/启动器、本地安装归档及 SHA256、README、公共 API 与 Python 标准库消费示例、JSON Schema、fixture 归属与冻结清单、开发验收环境锁定、CI 定义与实际运行范围、验收报告、第三方说明。建议项目采用 Apache-2.0；引用/移植 ReadStat 片段则保留 MIT 归属；PSPP 仅用于独立执行对照，不混入发行源码。实际 LICENSE 在实现阶段落地，未审清许可的文件不得打包。

## 12. 决策与待确认

无需先提供私有样例或证明课题组需求。没有真实样例时使用独立生成与合法公开文件；用户以后提供私有数据也默认只读，不默认上传或入仓库。

本设计的重要取舍是：首要用户为 MoonBit 集成开发者；首发完整 CLI 在 Node；小端 IEEE754 的 FL2 两种压缩；超长字符串和两类缺失列为必需；四种目标编码；日期只保留格式与原值；完整 bundle 始终带权威 NDJSON/metadata/codebook/manifest，默认另带标准 CSV 视图及配套 checker/消费示例。大端/ZSAV、自动日期转换和批处理后续再做。若用户接受这些范围，设计即可进入 PLAN 与 M1，无需为常规实现再次询问。

外部待确认仅影响赛事/发布：十一月规则与预研计入、正式报名/初审、Mooncakes owner。缺少这些不阻止本地实现；未获授权不推送、发布或报名。
