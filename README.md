# MoonSav

MoonBit 原生 SPSS `.sav` 字节读取库和离线 CLI。MoonBit 实现格式解析、传统压缩、字典、长字符串重组、标签/缺失语义以及 bundle 序列化和语义校验；Node 只负责文件、哈希、严格编码适配与进程入口。

版本 0.1.0。仓库已公开，当前默认分支包含 Node 包名导入、TypeScript 类型声明和安装后消费示例。冻结产品源码 `c89ce1a` 及其精确归档已于 2026-11-13 通过指定技术复验；旧封存版本与失败记录保留。当前源码、归档哈希、验证范围见[技术验收状态](docs/ACCEPTANCE_STATUS.md)和[交付清单](docs/delivery-manifest.json)。尚未公开发行到 npm/Mooncakes，技术验收不代表赛事审核或外部真人试用。

## 本地安装与第一次运行

CLI 需要 **Node24.15.0 / ICU78.2**，不需要 MoonBit、Python 或 C 编译器。包没有运行依赖，不联网。构建者运行 `node tools/build.mjs` 和 `npm pack --pack-destination dist`；使用者安装已经生成的归档：

```sh
npm install --offline --ignore-scripts ./dist/moonsav-0.1.0.tgz
./node_modules/.bin/moonsav --version
./node_modules/.bin/moonsav inspect ./node_modules/moonsav/fixtures/synthetic/survey-row.sav
./node_modules/.bin/moonsav validate ./node_modules/moonsav/fixtures/synthetic/survey-row.sav --json
./node_modules/.bin/moonsav export ./node_modules/moonsav/fixtures/synthetic/survey-row.sav --out first_bundle
./node_modules/.bin/moonsav check-bundle first_bundle --json
```

输出目录必须是新目录。保留原 SAV；不存在强制覆盖、自动续传、隐式修复或上传。文件路径含中文/空格时加引号。查看完整单列字典：`moonsav inspect INPUT.sav --variable score --json`。无参数/参数错误退出2，`--help` 退出0。

完整的对象、字段、默认值、单位、回调所有权、错误、输入输出与状态约束见 [CONTRACTS](docs/CONTRACTS.md)。回调字典与行使用独立快照，集合本身不是语言级深冻结。

## Node 程序集成

安装归档后可直接从包名导入；Node 运行时不需要 TypeScript 或其它 npm 运行依赖：

```js
import {readFileSync} from 'node:fs';
import {inspectSav, readSav, SavError} from 'moonsav';

const bytes = readFileSync('survey.sav');
const dictionary = inspectSav(bytes); // 只检查字典；actual_rows=null
const dataset = readSav(bytes);       // 完整扫描成功后才返回收集的行
console.log({declared: dictionary.declared_rows, actual: dataset.rows.length});
```

固定 Node24.15.0 也可以 `const {readSav} = require('moonsav')`。根入口仅导出 `SavError/inspectSav/readSav`；原 `moonsav/node/api.mjs` 及其它包内文件路径保持可访问，内部桥接接口不因此成为稳定 API。

随包声明支持 TypeScript 严格 NodeNext 检查，不引入运行依赖。Cell 和 Atom 使用判别联合，系统缺失的 decimal 为 null；声明行数也可能为 null。先判断 `cell.kind` 和 `cell.missing` 后消费值。选项显式 undefined 使用默认值，未知键及非法参数仍由运行时拒绝；类型检查不替代文件校验。返回集合是可修改快照，没有深冻结承诺。开放错误 code 需要未知值回退。

可直接运行不打印个体值的集成示例，输出实际行列数及每列 `[present,user,system]` 计数：

```sh
node node_modules/moonsav/examples/read_sav.mjs
node node_modules/moonsav/examples/read_sav.mjs "你的问卷.sav"
```

省略路径时使用随包合成样例。示例不猜测99/空白/NA的含义，不换算日期。readSav 会收集数据，小内存或逐行处理需求仍应使用 MoonBit scan_bytes 或 CLI 成套导出流程。完整类型与所有权定义见 CONTRACTS。

## 支持和边界

- 小端 IEEE754 `$FL2`，未压缩0和传统字节码1；已知/未知行数；非默认 bias。
- 1–32767字节字符串，包含13/14长名/分段、21值标签、22用户缺失，跨字节单元/分段后才解码；逻辑宽度内空格保留。字符串没有数值系统缺失。
- 数值/字符串值标签，离散/闭区间/范围加单值用户缺失，LOWEST/HIGHEST和系统哨兵；值标签从不替换数据，未声明缺失的99仍是合法值。数值保存 IEEE754 位，包含负零。
- UTF8、Microsoft CP1252、CP936/GBK稳定映射和GB18030稳定映射交集；具体白名单/版本/拒绝变体见 [CODEC_PROFILES](docs/CODEC_PROFILES.md)。不是所有GB18030版本。严格解码也不能证明提供方声明正确；覆盖用 `--encoding` 并产生提示。
- 日期始终保留原数值和print/write格式；数值变量任一格式为 GNU 日期/时间编码20–30或38–41时，每列给一次 RawDateFormat 提示，严格模式拒绝；PCT/DOT/自定义货币31–37不触发日期提示。分类依据 [GNU SAV 格式表](https://www.gnu.org/software/pspp/pspp-dev/html_node/Variable-Record.html)。测量/宽度/对齐按声明保留。已识别但未解释的文档/属性保留载荷并提示，未知扩展拒绝。
- 拒绝大端、IBM/VAX浮点、FL3/zlib/ZSAV、POR、未知编码/扩展、非哨兵NaN/Infinity及损坏输入。扩展名不能绕过检测。不写SAV，不统计分析，不自动替换标签/日期，不提供GUI/批量转换。

已执行的跨平台基线为源码 `5c1ff8d` 的 [CI42255719356](https://github.com/z2823253773-p/moonsav/actions/runs/42255719356)，四个作业全部通过；新修正版的对应 CI 以交付清单为准。Node24.15.0 / ICU78.2 固定，源码使用 toolchain.json 的完整编译器/core 配对。

| 已验证环境 | 实际范围 |
| --- | --- |
| macOS arm64 本地，两套工具链 | 完整 Node 语料；JS/native/wasm-gc 核心；完整兼容性、公开文件和精确归档消费 |
| Actions macOS15 | 共享及 POSIX Node 语料；JS/native/wasm-gc 核心；自建归档首次使用 |
| Actions Ubuntu24.04 x64 | 同上；另有完整 AC01–AC18、ReadStat/PSPP、源码消费和参考性能 |
| Actions Windows2025 x64 | 共享 Node 语料；JS/wasm-gc 核心；自建归档首次使用；不声称 native/POSIX 等价 |

本地与 Linux 完整入口均为17项通过及29个预期拒绝向量；两份公开 SAV 共65449个单元格对照无未解释差异。各 runner 自建归档，精确本地归档的消费另行记录，不能混为同一字节在三系统安装。

资源硬上限：输入256MiB，字典原始/解码各64MiB，逻辑变量100000，物理槽1000000，字符串32767，单标签1MiB，扩展16MiB，行8MiB，完整扫描1000000行；收集模式5000000单元/128MiB计费载荷，所有bundle文件合计512MiB。字典标签另按每项4096字节保守记账（默认最多16384个关联条目），在分配前拒绝；这是根据审查中的紧凑标签攻击收紧的资源策略。上限是应用记账，不是任意输入RSS承诺。

`--max-input-bytes N`、`--max-rows N`、`--max-output-bytes N` 只能下调正数。输入仍是受限内存字节，scan是逐行消费，**不是流式文件输入**。10,000×20参考性能和完整对照报告由交付清单指向当前证据，不外推到最大输入。

## 三个用户任务

U1：下方MoonBit API示例按类型和声明消费，过滤两类缺失、查询标签并安全保留旧行。

U2：先inspect理解字典；其 `validation_scope=dictionary_only`、actual_rows=null，尚未扫数据。validate扫完整文件并逐列报告present/user/system计数，每列总和等于实际行数；不输出个体样本。人类摘要最多20变量/10标签，明确显示展示数/总数；JSON完整。错误编码请核对提供方后显式覆盖；截断请重新取得完整文件；资源超限不会偷偷抽样。

U3：export创建配套bundle，然后check-bundle。默认有 `data.ndjson`（权威逐格值/位/原字节/missing）、`data.csv`（UTF8标准CSV视图）、`metadata.json`、`codebook.md`、`manifest.json`。`--format ndjson`仅省略CSV。CSV是逗号/CRLF/双引号，不定义反斜杠缺失token；`NA`、`\N`、前导零、尾空格均是原文。numeric系统缺失CSV固定`""`；字符串空白仍为空格。NUL不能进CSV，需选择NDJSON profile。

```sh
moonsav check-bundle first_bundle --json
python3 examples/read_bundle.py first_bundle
```

Python示例仅使用标准库，逐行读取权威NDJSON，再独立核对CSV，不做类型/NA推断。CSV单独不能普遍恢复源字节与缺失语义；普通表格软件可能推断数字、日期或公式，请按文本导入。日期和标签仍在metadata/codebook。

check-bundle 继承 bundle 元数据中已经记录的提示；旧包的错误提示不会自动重新分类，需要用修正版从原 SAV 重新导出。

checker只读，验证版本/文件集合/哈希/大小/类型/原位表示/逐格缺失/源字节解码/CSV一致性/计数。它拒绝INCOMPLETE、缺件、错配、路径逃逸和符号链接；额外普通文件明确未校验。它不是签名或来源认证：一致地改数据、字典和manifest可以形成另一个自洽bundle。

导出排他创建目录，先INCOMPLETE，写文件、关闭、最后manifest，移除INCOMPLETE才提交。提交前常规失败清理本次拥有的文件；中断可能留下未完成目录，换新目录重试。提交后报告失败时bundle可能完整，用checker恢复判断。POSIX新目录0700/文件0600；Windows沿用宿主ACL，不宣称相同权限位。

## MoonBit 集成

源构建只接受 toolchain.json 中两组精确配对：原基线 moon0.1.20260713 / moonc v0.10.4+2cc641edf，以及 CI 固定 moon0.1.20261023 / moonc v0.10.17+d971670cd。原版官方归档在已记录的安装尝试中返回403；现有原版工具链和项目隔离的新版均已验证，两版不混用 core。`--version` 报告实际构建配对。未发布到Mooncakes，使用本地源码归档解压后的路径依赖：

在消费者的 `moon.mod` 声明：

```moonbit
name = "example/consumer"
import { "z2823253773/moonsav@0.1.0" }
```

在同时包含消费者和解压库的目录写 `moon.work`：

```moonbit
members = ["consumer", "moonsav-source"]
```

工作区从本地解析库，不访问尚未发布的包；新版工具链不接受旧 JSON 模块配置。随包示例已提供 `moon.mod`、`moon.pkg`、`moon.work`，两组固定工具链都可运行。若旧 MoonBit 在源码消费时因环境变量 `_` 含非法 UTF-8 路径崩溃，可只对该进程移除该变量后重试，例如 `env -u _ moon run . --target js`；诊断原文在指定复验材料中保留，这不属于 SAV 读取失败。参见 [MoonBit 本地依赖说明](https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html#dependency-management)。

包import：`"z2823253773/moonsav"`。完整可编译例子在 `examples/consumer/main.mbt`（包含合成SAV字节，无文件I/O）；从该目录执行 `moon run . --target js`，也可native/wasm-gc。库不读文件、不打印、不退出进程。

```moonbit
let dataset = @moonsav.read_bytes(bytes)
let score = dataset.dictionary.variables[0]
let present = dataset.rows.filter(row => !row[0].is_missing())
let label = score.value_label_for(dataset.rows[0][0])
```

`inspect_bytes(Bytes, options?) -> Dictionary raise SavError`；`read_bytes -> Dataset`；`scan_bytes(Bytes, on_dictionary, on_row, options?) -> ScanSummary raise SavError`。回调是同步背压；返回Continue/Stop。Stop得到completed=false和实际处理行数；回调抛错得到ConsumerFailed。后续行不会修改先前返回的行或单元。调用方自行无限缓存不计入库预算。

Options包含limits、encoding_override、DatePolicy::Raw及严格decoder回调；自定义适配器必须同时提供decoder_identity（实现及版本），并自行完成profile验证。默认core只支持UTF8；其他编码必须提供经过验证的Decoder，否则UnsupportedEncoding。Node的 `node/api.mjs` 提供inspectSav/readSav，CLI使用同一编译的MoonBit核心；这个适配层同步且禁止重入。

`Cell`明确区分kind/missing/decimal/ieee754_hex/text/logical_bytes_base64，API有missing_kind/is_missing，Variable有value_label_for。名字保留大小写、按稳定零基index定位；错误结构带code/message/可用时byte_offset、变量/行等上下文。数据定义和schema位于schemas/。

## 错误、验证和开发

成功0；参数2；I/O/目录冲突/输入变化3；损坏/完整性4；不支持/编码要求/CSV表示5；资源6；`--fail-on-warning`拒绝7；内部70。JSON成功stdout一条，失败stderr一条；提示不是损坏，严格export有提示时不会提交。

```sh
python3.12 -m venv .dev/venv
.dev/venv/bin/python -m pip install -r requirements-dev.lock
npm ci --ignore-scripts
node tools/build.mjs
npm test
moon test src --target js
moon test src --target native
moon test src --target wasm-gc
.dev/venv/bin/python tools/verify.py --all --require-public --require-pspp --output evidence/my-run
```

TypeScript5.9.3只用于开发测试；先执行 npm ci --ignore-scripts。运行已安装的CLI/API不需要它。公共语料下载到忽略的.cache，Python/PSPP验证环境在.dev。`tools/setup-pspp.sh`提供本机源码构建步骤；也可设MOONSAV_PSPP使用独立安装。ReadStat/PSPP两家族、两份公开实际文件全量比较与失败分类均写入run.json/summary.json，不能用单测通过替代它们。Mac系统iconv对GB18030补充平面向量的已知oracle限制单独保留；相应四字节向量由GNU PSPP+独立Python/一手映射对照，不把oracle失败算产品通过或悄悄删除用例。

Apache-2.0；第三方映射许可见 [THIRD_PARTY](THIRD_PARTY.md)。原始私有数据只读且不默认上传/入库。[公开 GitHub 仓库](https://github.com/z2823253773-p/moonsav)创建、公开、推送和 Actions 已获授权并执行；历史失败日志与成功结果分别保留。没有执行公开 npm/Mooncakes 发行、赛事报名或提交；赛事规则与初审认可需另按官方要求核对，没有外部真人试用反馈。
