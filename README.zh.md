[English](README.md) | [简体中文](README.zh.md)

# R4eGPS

R4eGPS 是一个 R 语言包，它提供了 R 语言与 eGPS 软件之间的接口。该包通过 rJava 包实现 R 与 Java 程序的交互，使用户能够在 R 环境中直接调用 eGPS 软件的功能。

## 描述

R4eGPS 包允许用户在 R 环境中使用 eGPS 软件的各种功能，包括基因结构可视化、系统发育树分析、FASTA 文件处理、分类学信息获取等。它通过 Java 接口与 eGPS 软件进行通信，为生物信息学研究提供了强大的工具集。

使用此包需要先安装并配置 eGPS 软件环境。

**注意：此 R 包仍在不断完善中。由于开发者无法预知所有具体应用场景的需求，我们提出了一个通用框架。文档中的示例仅作为引导，用户可以根据自己的需求进行扩展和定制。**

## 主要特性

- **eGPS 软件集成**: 提供启动和使用 eGPS 软件的接口函数
- **基因结构可视化**: 支持多基因结构的可视化展示
- **系统发育树分析**: 提供获取系统发育树节点名称等功能
- **FASTA 文件处理**: 支持从 FASTA 文件中提取特定序列
- **分类学信息查询**: 可以获取 NCBI 分类学谱系信息
- **表达谱相关性可视化**: 支持基因表达数据的相关性可视化分析
- **HMMER 结果处理**: 提供将 HMMER domtbl 输出转换为 TSV 格式的功能

## 安装说明

1. 首先确保已安装 R 和 Java 环境
2. 安装依赖包:
```R
install.packages(c("rJava", "jsonlite", "rlang"))
```
3. 安装 R4eGPS 包:
```R
# 从 GitHub 安装（假设）
devtools::install_github("username/R4eGPS")
```
4. 配置 eGPS 软件路径:
```R
R4eGPS::setGlobalVars(list(eGPS_software_path = "/path/to/eGPS/software"))
```

## 使用示例

```R
library(R4eGPS)

# 启动 eGPS 软件
egps <- launchEGPS_withinR()

# 基因结构可视化
gene_list <- list(
  gene1 = list(
    length = 250,
    start = c(1, 10, 101, 200),
    end = c(8, 56, 152, 230),
    color = c("#E63946", "#457B9D", "#2A9D8F", "#F4A261")
  )
)
structDraw_multi_genes(gene_list)

# FASTA 文件序列提取
fastadumper_partialMatch(
  fastaPath = "input.fasta",
  entries = c("gene1", "gene2"),
  outPath = "output.fasta"
)

# 系统发育树节点名称获取
node_names <- evoltre_getNodeNames("tree.nwk", getOTU = TRUE, getHTU = FALSE)
```

## 许可证

本项目采用 GPL-3.0 许可证 - 查看 [LICENSE.md](LICENSE.md) 文件了解详情。