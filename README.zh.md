[English](README.md) | [简体中文](README.zh.md)

# R4eGPS

`R4eGPS` 是 eGPS 的 R 封装。现在推荐的运行模型是“正式安装版 eGPS + 安装包自带 `dependency-egps` 和 `jre`”。源码树布局仍然支持，但主要用于开发调试，不是普通用户默认场景。

当前 wrapper 重点覆盖：

- 启动 eGPS desktop
- 打开 `Modern Tree View`
- 打开 `Pathway Family Browser`
- 通过当前 Java bridge 提取树节点名称

## 环境要求

- 当前工作区已验证的 R 版本是 `4.5.2`
- 一个可用的 eGPS 安装目录，例如 `C:/path/to/eGPS_v2.1_windows_x64_selfTest`
- 安装目录中应包含：
  - `dependency-egps/`
  - `eGPS2.args`
  - `jre/bin/server/jvm.dll`
- 所有 JVM 相关调用都依赖 `rJava`
- 包的 Imports 包括：
  - `jsonlite`
  - `rlang`

## 本地安装 R4eGPS

在 R 中执行：

```r
install.packages(
  "C:/path/to/egps2_collections/R4eGPS",
  repos = NULL,
  type = "source"
)
```

这条本地安装路径已经在当前工作区实测通过，并且后续 `library(R4eGPS)` smoke 也跑通过了。

## 运行时模型

`configureEGPSSourceRuntime(repoRoot=...)` 目前接受三种路径：

- 正式安装版 eGPS 根目录，例如 `C:/path/to/eGPS_v2.1_windows_x64_selfTest`
- 上述目录里的 `dependency-egps` 子目录
- 源码树根目录，仅供开发调试使用

当 `repoRoot` 指向安装版 eGPS 时：

- JVM 参数从 `eGPS2.args` 读取
- classpath 从 `dependency-egps/*.jar` 组装
- 如果没有显式传 `javaPath`，默认自动使用安装包里的 `jre/bin/server/jvm.dll`

当 `repoRoot` 指向源码树时：

- JVM 参数从 `egps-main.gui/eGPS.args` 读取
- classpath 使用两个 `out/production/...` 目录加源码树里的两个 `dependency-egps` 目录

## 首次配置

推荐显式配置：

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)
```

也可以直接传安装版的 `dependency-egps` 目录：

```r
configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest/dependency-egps"
)
```

如果是安装版路径，并且没有显式指定 `javaPath`，`R4eGPS` 会自动使用：

```text
<install-root>/jre/bin/server/jvm.dll
```

如果用户还没有配置过运行时，并且当前是交互式会话，那么第一次调用需要 JVM 的函数时，`R4eGPS` 会提示用户选择 eGPS 安装路径，并把结果持久化到：

```text
~/.R4eGPS.package.vars.rds
```

如果你想强制重新选择路径，删掉这个文件即可。

注意：非交互脚本不要依赖这个提示。批处理、Rscript、自动化任务里都应该先显式调用 `configureEGPSSourceRuntime(...)`。

## 公开 API

主要导出函数包括：

- `configureEGPSSourceRuntime()`
- `launchEGPSDesktop()`
- `launchEGPS_withinR()`
- `openModernTreeView()`
- `openModernTreeViewFromConfig()`
- `openPathwayFamilyBrowser()`
- `openPathwayFamilyBrowserFromConfig()`
- `evoltre_getNodeNames()`

兼容层说明：

- `launchEGPS_withinR()` 仍然保留，但新代码建议优先使用 `launchEGPSDesktop()`

## 快速开始

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)

egps <- launchEGPSDesktop()
```

正常情况下会打印类似这样的欢迎信息：

```text
Hello this is eGPS desktop, version: Version: 2.1.97
```

`launchEGPSDesktop()` 在启动桌面后会返回 Java bridge 对象。

## Modern Tree View

`openModernTreeView(...)` 支持两种树输入：

- `treePath`：已有 Newick 文件路径
- `newickText`：直接传 Newick 字符串

二者必须二选一。

其他常用参数包括：

- `layout`
- `leafLabel`
- `title`
- `reverseAxis`
- `blankSpace`
- `nodeVisualConfigPath`

示例：

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)

openModernTreeView(
  newickText = "(Human:6.5,Chimp:6.5,Gorilla:8.9);",
  layout = "CIRCULAR",
  leafLabel = TRUE,
  title = "Great apes",
  reverseAxis = FALSE,
  blankSpace = c(20, 40, 80, 40)
)
```

如果你已经有 VOICE 配置文件，可以直接调用：

```r
openModernTreeViewFromConfig("C:/path/to/modern_tree.voice")
```

## Pathway Family Browser

`openPathwayFamilyBrowser(...)` 支持以下输入：

- `treePath` 或 `newickText`
- `componentCounts`
- `speciesInfo`
- `speciesTraits`
- `galleryPaths`
- `layout`
- `leafLabel`
- `title`
- `reverseAxis`
- `blankSpace`
- `nodeVisualConfigPath`

输入规则如下：

- `componentCounts`、`speciesInfo`、`speciesTraits` 可以是文件路径，也可以是 `data.frame`
- 如果传 `data.frame`，必须包含 `Name` 列
- `galleryPaths` 必须是真实文件路径
- 某个表格参数如果传 `NULL`，生成的 VOICE 配置会把该字段写成 `False`

示例：

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)

componentCounts <- data.frame(
  Name = c("Human", "Chimp"),
  WNT3A = c(2, 1)
)

speciesInfo <- data.frame(
  Name = c("Human", "Chimp"),
  Clade = c("Hominini", "Hominini")
)

speciesTraits <- data.frame(
  Name = c("Human", "Chimp"),
  Habitat = c("Mixed", "Forest")
)

openPathwayFamilyBrowser(
  treePath = "C:/path/to/species_tree.nwk",
  componentCounts = componentCounts,
  speciesInfo = speciesInfo,
  speciesTraits = speciesTraits,
  galleryPaths = c(
    "C:/path/to/wnt_pathway.pptx"
  ),
  layout = "RECTANGULAR",
  leafLabel = TRUE,
  title = "WNT pathway family"
)
```

如果已经有现成的 VOICE 配置文件，可以直接：

```r
openPathwayFamilyBrowserFromConfig("C:/path/to/pathway_browser.voice")
```

## 树工具 Bridge

树节点提取入口为：

```r
node_names <- evoltre_getNodeNames(
  "C:/path/to/species_tree.nwk",
  targetHTU = NULL,
  getOTU = TRUE,
  getHTU = FALSE
)
```

这里底层调用的是当前 Java bridge：

```text
api.rpython.API4R.extractNodeNames(...)
```

## 运行时注意事项

- GUI 是嵌在当前 R 进程里的。如果脚本马上退出，窗口也可能马上消失。
- 做 smoke test 时，建议在打开 GUI 后 `Sys.sleep()` 几秒，留出观察时间。
- `openModernTreeView(...)` 和 `openPathwayFamilyBrowser(...)` 的主要目的就是触发 Java GUI，不是返回复杂的 R 对象。
- 新代码建议统一从 `launchEGPSDesktop()` 进入 desktop。

一个最小 smoke 模式如下：

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)

launchEGPSDesktop()
Sys.sleep(8)
```

## 排错

### 看不到 GUI

- 先确认 `repoRoot` 指向的是安装根目录或其 `dependency-egps` 子目录
- 确认安装目录里确实有 `eGPS2.args`、`dependency-egps`、`jre/bin/server/jvm.dll`
- 确认打开窗口后 R 会话没有立刻退出

### 为什么会突然提示选择路径

- 说明当前没有已持久化的运行时配置，并且你也没有显式传 `repoRoot`
- 自动化脚本里不要依赖它，始终先调用 `configureEGPSSourceRuntime(...)`

### `rJava` 报错

- 在目标 R 环境里先安装 `rJava`
- 当前已经验证过的 R 可执行文件是 `C:/R_envs/R-4.5.2/bin/Rscript.exe`

### Pathway Family Browser 的 `data.frame` 输入报错

- 检查每个 `data.frame` 是否都包含 `Name` 列
- 检查 `galleryPaths` 是否都是真实文件

### 想重新指定 eGPS 安装目录

- 删除 `~/.R4eGPS.package.vars.rds`
- 或者再次调用 `configureEGPSSourceRuntime(...)`

## 验证

helper 验证：

```r
Rscript tests/test_runtime_helpers.R
```

本地安装路径也已验证通过：

```r
install.packages(
  "C:/path/to/egps2_collections/R4eGPS",
  repos = NULL,
  type = "source"
)
library(R4eGPS)
```
