[English](README.md) | [简体中文](README.zh.md)

# R4eGPS

R4eGPS is an R package that provides an interface between the R language and the eGPS software. The package enables users to call eGPS software functions directly within the R environment through the rJava package.

## Description

The R4eGPS package allows users to utilize various functions of the eGPS software within the R environment, including gene structure visualization, phylogenetic tree analysis, FASTA file processing, taxonomy information retrieval, and more. It communicates with the eGPS software through Java interfaces, providing a powerful toolkit for bioinformatics research.

Using this package requires prior installation and configuration of the eGPS software environment.

**Note: This R package is still under continuous development. Since the developers cannot anticipate all the specific application scenarios and their requirements, we have proposed a universal framework. The examples in the documentation are just starters, and users can extend and customize according to their own needs.**

## Key Features

- **eGPS Software Integration**: Provides interface functions to launch and use eGPS software
- **Gene Structure Visualization**: Supports visualization of multi-gene structures
- **Phylogenetic Tree Analysis**: Functions to retrieve node names from phylogenetic trees
- **FASTA File Processing**: Extract specific sequences from FASTA files
- **Taxonomy Information Retrieval**: Obtain NCBI taxonomic lineage information
- **Expression Profile Correlation Visualization**: Supports correlation visualization analysis of gene expression data
- **HMMER Result Processing**: Convert HMMER domtbl output to TSV format

## Installation Instructions

1. Ensure R and Java environments are installed
2. Install dependency packages:
```R
install.packages(c("rJava", "jsonlite", "rlang"))
```
3. Install the R4eGPS package:
```R
# Install from GitHub (assumed)
devtools::install_github("username/R4eGPS")
```
4. Configure eGPS software path:
```R
R4eGPS::setGlobalVars(list(eGPS_software_path = "/path/to/eGPS/software"))
```

## Usage Examples

```R
library(R4eGPS)

# Launch eGPS software
egps <- launchEGPS_withinR()

# Gene structure visualization
gene_list <- list(
  gene1 = list(
    length = 250,
    start = c(1, 10, 101, 200),
    end = c(8, 56, 152, 230),
    color = c("#E63946", "#457B9D", "#2A9D8F", "#F4A261")
  )
)
structDraw_multi_genes(gene_list)

# Extract sequences from FASTA file
fastadumper_partialMatch(
  fastaPath = "input.fasta",
  entries = c("gene1", "gene2"),
  outPath = "output.fasta"
)

# Get phylogenetic tree node names
node_names <- evoltre_getNodeNames("tree.nwk", getOTU = TRUE, getHTU = FALSE)
```

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE.md](LICENSE.md) file for details.