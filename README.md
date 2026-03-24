[English](README.md) | [简体中文](README.zh.md)

# R4eGPS

`R4eGPS` is the R wrapper for eGPS. Its primary runtime model is the installed Windows eGPS package, including the bundled `dependency-egps` jars and bundled `jre`. Source-tree resolution is still supported for development, but normal usage should point to the installed eGPS folder.

The wrapper currently focuses on:

- launching the eGPS desktop
- opening `Modern Tree View`
- opening `Pathway Family Browser`
- extracting tree node names through the current Java bridge

## Requirements

- R `4.5.2` was verified in the current workspace
- a working eGPS installation, for example `C:/path/to/eGPS_v2.1_windows_x64_selfTest`
- the eGPS installation must contain:
  - `dependency-egps/`
  - `eGPS2.args`
  - `jre/bin/server/jvm.dll`
- `rJava` is required for JVM-backed calls
- package imports:
  - `jsonlite`
  - `rlang`

## Install R4eGPS Locally

From R:

```r
install.packages(
  "C:/path/to/egps2_collections/R4eGPS",
  repos = NULL,
  type = "source"
)
```

That local package install flow was verified in the current workspace, followed by `library(R4eGPS)`.

## Runtime Model

`configureEGPSSourceRuntime(repoRoot=...)` accepts:

- the installed eGPS root, such as `C:/path/to/eGPS_v2.1_windows_x64_selfTest`
- the installed `dependency-egps` directory inside that root
- the source-tree root, for development only

When the runtime points to an installed eGPS package:

- JVM options are read from `eGPS2.args`
- the classpath is built from `dependency-egps/*.jar`
- the bundled `jre/bin/server/jvm.dll` is used automatically unless `javaPath` is provided

When the runtime points to the source tree:

- JVM options are read from `egps-main.gui/eGPS.args`
- the classpath uses both compiled `out/production/...` directories plus both source-tree `dependency-egps` directories

## First-Time Configuration

The recommended setup is:

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)
```

You can also point directly to the installed dependency directory:

```r
configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest/dependency-egps"
)
```

If `javaPath` is omitted for an installed package, `R4eGPS` uses:

```text
<install-root>/jre/bin/server/jvm.dll
```

If no runtime has been configured yet and a JVM-backed call is made in an interactive session, `R4eGPS` will ask the user to choose the eGPS installation folder and persist the result in:

```text
~/.R4eGPS.package.vars.rds
```

Delete that file if you want the package to prompt again.

For non-interactive scripts, do not rely on the prompt. Always call `configureEGPSSourceRuntime(...)` explicitly.

## Public API

The main exported functions are:

- `configureEGPSSourceRuntime()`
- `launchEGPSDesktop()`
- `launchEGPS_withinR()`
- `openModernTreeView()`
- `openModernTreeViewFromConfig()`
- `openPathwayFamilyBrowser()`
- `openPathwayFamilyBrowserFromConfig()`
- `evoltre_getNodeNames()`

For legacy code:

- `launchEGPS_withinR()` is still kept, but new code should prefer `launchEGPSDesktop()`

## Quick Start

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)

egps <- launchEGPSDesktop()
```

On a healthy runtime the desktop launch prints a message similar to:

```text
Hello this is eGPS desktop, version: Version: 2.1.97
```

`launchEGPSDesktop()` returns the Java bridge object invisibly after launching the desktop.

## Modern Tree View

`openModernTreeView(...)` supports:

- `treePath`: path to an existing Newick file
- `newickText`: raw Newick text

Exactly one of them must be supplied.

Other supported parameters:

- `layout`
- `leafLabel`
- `title`
- `reverseAxis`
- `blankSpace`
- `nodeVisualConfigPath`

Example:

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

If you already have a VOICE config file, use:

```r
openModernTreeViewFromConfig("C:/path/to/modern_tree.voice")
```

## Pathway Family Browser

`openPathwayFamilyBrowser(...)` supports:

- `treePath` or `newickText`
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

Input rules:

- `componentCounts`, `speciesInfo`, and `speciesTraits` can be file paths or `data.frame`
- every `data.frame` input must contain a `Name` column
- `galleryPaths` must be real file paths
- if a table argument is `NULL`, the generated VOICE config writes `False`

Example:

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

If you already have a VOICE config file, use:

```r
openPathwayFamilyBrowserFromConfig("C:/path/to/pathway_browser.voice")
```

## Tree Utility Bridge

Tree node extraction uses:

```r
node_names <- evoltre_getNodeNames(
  "C:/path/to/species_tree.nwk",
  targetHTU = NULL,
  getOTU = TRUE,
  getHTU = FALSE
)
```

This now calls the current Java bridge method:

```text
api.rpython.API4R.extractNodeNames(...)
```

## Important Runtime Notes

- The GUI runs inside the current R process. If the script exits immediately, the GUI may disappear immediately as well.
- For quick smoke tests, keep the R session alive for a few seconds after opening a window.
- `openModernTreeView(...)` and `openPathwayFamilyBrowser(...)` mainly trigger Java GUI work. Their return values are not the primary output.
- `launchEGPSDesktop()` is the recommended desktop entry point for new code.

Example smoke pattern:

```r
library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/path/to/eGPS_v2.1_windows_x64_selfTest"
)

launchEGPSDesktop()
Sys.sleep(8)
```

## Troubleshooting

### No GUI appears

- Check that `repoRoot` points to the installed eGPS root or its `dependency-egps` directory
- Check that the installed package contains `eGPS2.args`, `dependency-egps`, and `jre/bin/server/jvm.dll`
- Keep the R session alive for a few seconds after opening the GUI

### The package asks for a path unexpectedly

- That means no persisted runtime is available and no explicit `repoRoot` was provided
- In automated scripts, always call `configureEGPSSourceRuntime(...)` first

### `rJava` errors

- Install `rJava` in the target R environment before calling GUI functions
- The current verified R executable is `C:/R_envs/R-4.5.2/bin/Rscript.exe`

### Pathway Family Browser data.frame input fails

- Check that each `data.frame` includes a `Name` column
- Check that `galleryPaths` points to real files

### You want to reconfigure the eGPS installation path

- Delete `~/.R4eGPS.package.vars.rds`
- Or call `configureEGPSSourceRuntime(...)` again with a different `repoRoot`

## Verification

Helper verification:

```r
Rscript tests/test_runtime_helpers.R
```

The local install flow was also verified with:

```r
install.packages(
  "C:/path/to/egps2_collections/R4eGPS",
  repos = NULL,
  type = "source"
)
library(R4eGPS)
```
