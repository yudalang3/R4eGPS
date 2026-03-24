#' Configure the eGPS runtime for R4eGPS.
#'
#' `repoRoot` can be one of:
#' - the installed eGPS root
#' - the formal package root
#' - the `dependency-egps` directory inside the formal package
#'
#' @param repoRoot The eGPS runtime path.
#' @param javaPath Optional path to `java.exe`, `javaw.exe`, or `jvm.dll`.
#'
#' @return Invisibly returns the stored runtime configuration.
#' @export
configureEGPSSourceRuntime <- function(repoRoot, javaPath = NA_character_) {
  if (rlang::is_missing(repoRoot)) {
    rlang::abort("Please input the repoRoot argument.")
  }

  runtimeLayout <- .resolveRuntimeLayout(repoRoot, quiet = FALSE)
  vars <- getGlobalVars()
  if (is.null(vars)) {
    vars <- list()
  }

  vars[[egps_repo_root_key]] <- runtimeLayout$root
  if (!is.na(javaPath) && nzchar(javaPath)) {
    vars[[java_path_key]] <- .normalizePathForJava(javaPath, mustWork = TRUE)
  } else if (!is.na(runtimeLayout$bundledJvmPath)) {
    vars[[java_path_key]] <- runtimeLayout$bundledJvmPath
  }

  setGlobalVars(vars)
  invisible(vars)
}


.normalizePathForJava <- function(path, mustWork = TRUE) {
  normalizePath(path, winslash = "/", mustWork = mustWork)
}


.voiceBool <- function(value) {
  if (isTRUE(value)) {
    return("T")
  }
  "F"
}


.coerceStoredVars <- function(vars) {
  if (is.null(vars)) {
    return(NULL)
  }
  if (is.environment(vars)) {
    return(as.list(vars, all.names = TRUE))
  }
  as.list(vars)
}


.findSourceTreeRoot <- function(path) {
  current <- normalizePath(path, winslash = "/", mustWork = FALSE)
  while (!identical(current, dirname(current))) {
    if (dir.exists(file.path(current, "egps-main.gui")) &&
        dir.exists(file.path(current, "egps-pathway.evol.browser"))) {
      return(current)
    }
    current <- dirname(current)
  }

  if (dir.exists(file.path(current, "egps-main.gui")) &&
      dir.exists(file.path(current, "egps-pathway.evol.browser"))) {
    return(current)
  }

  NA_character_
}


.findBundleRoot <- function(path) {
  current <- normalizePath(path, winslash = "/", mustWork = FALSE)
  while (!identical(current, dirname(current))) {
    if (dir.exists(file.path(current, "dependency-egps")) &&
        file.exists(file.path(current, "eGPS2.args"))) {
      return(current)
    }
    if (basename(current) == "dependency-egps" &&
        file.exists(file.path(dirname(current), "eGPS2.args"))) {
      return(dirname(current))
    }
    current <- dirname(current)
  }

  if (dir.exists(file.path(current, "dependency-egps")) &&
      file.exists(file.path(current, "eGPS2.args"))) {
    return(current)
  }

  if (basename(current) == "dependency-egps" &&
      file.exists(file.path(dirname(current), "eGPS2.args"))) {
    return(dirname(current))
  }

  NA_character_
}


.findBundledJvmPath <- function(runtimeRoot) {
  bundledJvmPath <- file.path(runtimeRoot, "jre", "bin", "server", "jvm.dll")
  if (file.exists(bundledJvmPath)) {
    return(.normalizePathForJava(bundledJvmPath, mustWork = TRUE))
  }
  NA_character_
}


.buildSourceTreeClassPath <- function(runtimeRoot) {
  classPathEntries <- c(
    file.path(runtimeRoot, "egps-main.gui", "out", "production", "egps-main.gui"),
    file.path(runtimeRoot, "egps-pathway.evol.browser", "out", "production", "egps-pathway.evol.browser"),
    list.files(file.path(runtimeRoot, "egps-main.gui", "dependency-egps"), pattern = "\\.jar$", full.names = TRUE),
    list.files(file.path(runtimeRoot, "egps-pathway.evol.browser", "dependency-egps"), pattern = "\\.jar$", full.names = TRUE)
  )
  unique(.normalizePathForJava(classPathEntries, mustWork = TRUE))
}


.buildBundleClassPath <- function(runtimeRoot) {
  classPathEntries <- list.files(
    file.path(runtimeRoot, "dependency-egps"),
    pattern = "\\.jar$",
    full.names = TRUE
  )
  unique(.normalizePathForJava(classPathEntries, mustWork = TRUE))
}


.layoutFromCandidate <- function(candidate) {
  if (is.na(candidate) || !nzchar(candidate)) {
    return(NULL)
  }

  sourceTreeRoot <- .findSourceTreeRoot(candidate)
  if (!is.na(sourceTreeRoot)) {
    return(list(
      kind = "source_tree",
      root = sourceTreeRoot,
      argsPath = file.path(sourceTreeRoot, "egps-main.gui", "eGPS.args"),
      classPathEntries = .buildSourceTreeClassPath(sourceTreeRoot),
      bundledJvmPath = NA_character_
    ))
  }

  bundleRoot <- .findBundleRoot(candidate)
  if (!is.na(bundleRoot)) {
    return(list(
      kind = "bundle",
      root = bundleRoot,
      argsPath = file.path(bundleRoot, "eGPS2.args"),
      classPathEntries = .buildBundleClassPath(bundleRoot),
      bundledJvmPath = .findBundledJvmPath(bundleRoot)
    ))
  }

  NULL
}


.discoverRepoRoot <- function() {
  discoveredLayout <- .layoutFromCandidate(getwd())
  if (!is.null(discoveredLayout)) {
    return(discoveredLayout$root)
  }
  NA_character_
}


.promptForRuntimeRoot <- function() {
  promptTitle <- "Select the eGPS installation folder or dependency-egps directory."

  if (.Platform$OS.type == "windows" && interactive()) {
    selectedPath <- tryCatch(
      utils::choose.dir(caption = promptTitle),
      error = function(...) NA_character_
    )
    if (!is.na(selectedPath) && nzchar(selectedPath)) {
      return(.normalizePathForJava(selectedPath, mustWork = TRUE))
    }
  }

  if (interactive()) {
    selectedPath <- trimws(readline(paste(promptTitle, "\nPath: ")))
    selectedPath <- gsub('^"|"$', "", selectedPath)
    if (nzchar(selectedPath)) {
      return(.normalizePathForJava(selectedPath, mustWork = TRUE))
    }
  }

  NA_character_
}


.resolveRuntimeLayout <- function(repoRoot = NA_character_, quiet = TRUE) {
  if (!is.na(repoRoot) && nzchar(repoRoot)) {
    layout <- .layoutFromCandidate(repoRoot)
    if (!is.null(layout)) {
      return(layout)
    }
    if (quiet) {
      return(NULL)
    }
    rlang::abort(
      "repoRoot must point to the eGPS installation root, the formal package root, or the dependency-egps directory."
    )
  }

  vars <- .coerceStoredVars(getGlobalVars())
  if (!is.null(vars)) {
    storedRepoRoot <- vars[[egps_repo_root_key]]
    if (!is.null(storedRepoRoot) && nzchar(storedRepoRoot)) {
      layout <- .layoutFromCandidate(storedRepoRoot)
      if (!is.null(layout)) {
        return(layout)
      }
    }

    legacyPath <- vars[[eGPS_software_path_key]]
    if (!is.null(legacyPath) && nzchar(legacyPath)) {
      layout <- .layoutFromCandidate(legacyPath)
      if (!is.null(layout)) {
        if (!quiet) {
          message("Detected legacy eGPS_software_path; please migrate to egps_repo_root via configureEGPSSourceRuntime().")
        }
        return(layout)
      }
    }
  }

  discovered <- .discoverRepoRoot()
  if (!is.na(discovered)) {
    layout <- .layoutFromCandidate(discovered)
    if (!is.null(layout)) {
      return(layout)
    }
  }

  if (!quiet) {
    promptedPath <- .promptForRuntimeRoot()
    if (!is.na(promptedPath) && nzchar(promptedPath)) {
      configureEGPSSourceRuntime(promptedPath)
      return(.resolveRuntimeLayout(promptedPath, quiet = FALSE))
    }
  }

  if (quiet) {
    return(NULL)
  }

  rlang::abort(
    paste(
      "Unable to locate a valid eGPS runtime.",
      "Please pass the installation root or dependency-egps directory to configureEGPSSourceRuntime()."
    )
  )
}


.resolveSourceTreeRoot <- function(repoRoot = NA_character_, quiet = TRUE) {
  runtimeLayout <- .resolveRuntimeLayout(repoRoot, quiet = quiet)
  if (is.null(runtimeLayout)) {
    return(NA_character_)
  }
  runtimeLayout$root
}


.getConfiguredJavaPath <- function(runtimeLayout = NULL) {
  vars <- .coerceStoredVars(getGlobalVars())
  if (!is.null(vars)) {
    javaPath <- vars[[java_path_key]]
    if (!is.null(javaPath) && nzchar(javaPath)) {
      return(.normalizePathForJava(javaPath, mustWork = TRUE))
    }
  }

  if (!is.null(runtimeLayout) && !is.na(runtimeLayout$bundledJvmPath)) {
    return(runtimeLayout$bundledJvmPath)
  }

  NA_character_
}


.inferJavaHome <- function(javaPath) {
  normalizedPath <- .normalizePathForJava(javaPath, mustWork = TRUE)
  lowerPath <- tolower(normalizedPath)

  if (grepl("/jvm\\.dll$", lowerPath)) {
    return(dirname(dirname(dirname(normalizedPath))))
  }
  if (grepl("/javaw?\\.exe$", lowerPath)) {
    return(dirname(dirname(normalizedPath)))
  }

  dirname(normalizedPath)
}


.getRuntimeClassPathEntries <- function(repoRoot) {
  runtimeLayout <- .resolveRuntimeLayout(repoRoot, quiet = FALSE)
  runtimeLayout$classPathEntries
}


.parseEGPSArgs <- function(repoRoot) {
  runtimeLayout <- .resolveRuntimeLayout(repoRoot, quiet = FALSE)
  lines <- readLines(runtimeLayout$argsPath, warn = FALSE, encoding = "UTF-8")
  lines <- trimws(lines)
  lines <- Filter(function(line) nzchar(line) && !startsWith(line, "#"), lines)
  vapply(lines, .normalizeJvmArg, character(1))
}


.normalizeJvmArg <- function(argument) {
  if (startsWith(argument, "--add-exports ") || startsWith(argument, "--add-opens ")) {
    return(sub(" ", "=", argument, fixed = TRUE))
  }
  argument
}


.getJavaParametersForRuntime <- function(repoRoot) {
  unique(c(
    "-Dfile.encoding=UTF-8",
    "-Dstdout.encoding=UTF-8",
    "-Dstderr.encoding=UTF-8",
    getOption("java.parameters", character()),
    .parseEGPSArgs(repoRoot)
  ))
}


.requireRJava <- function() {
  if (!requireNamespace("rJava", quietly = TRUE)) {
    rlang::abort(
      paste(
        "The rJava package is required for GUI integration.",
        "Install it in", shQuote(file.path("C:/R_envs/R-4.5.2", "bin", "R.exe")),
        "or via install.packages('rJava') before calling GUI functions."
      )
    )
  }
}


.getBridgeInstance <- function() {
  initializeJVM4eGPS()
  rJava::.jnew("api.rpython.RlangInterfaceEGPS")
}


.materializeTreeInput <- function(treePath = NA_character_, newickText = NULL) {
  hasTreePath <- !is.na(treePath) && nzchar(treePath)
  hasNewickText <- !is.null(newickText) && nzchar(newickText)
  if (hasTreePath == hasNewickText) {
    rlang::abort("Provide exactly one of treePath or newickText.")
  }

  if (hasTreePath) {
    return(.normalizePathForJava(treePath, mustWork = FALSE))
  }

  tempTreePath <- tempfile(fileext = ".nwk")
  writeLines(newickText, tempTreePath, useBytes = TRUE)
  .normalizePathForJava(tempTreePath, mustWork = FALSE)
}


.materializeTableInput <- function(value) {
  if (is.null(value)) {
    return("False")
  }
  if (is.data.frame(value)) {
    if (!"Name" %in% colnames(value)) {
      rlang::abort("Data frame inputs must contain a 'Name' column.")
    }
    tempPath <- tempfile(fileext = ".tsv")
    writeDataFrameToTsv(value, tempPath)
    return(.normalizePathForJava(tempPath, mustWork = FALSE))
  }
  .normalizePathForJava(value, mustWork = FALSE)
}


.normalizeGalleryPaths <- function(galleryPaths) {
  if (is.null(galleryPaths)) {
    return(NULL)
  }
  vapply(galleryPaths, .normalizePathForJava, character(1), mustWork = FALSE)
}


.normalizeBlankSpace <- function(blankSpace) {
  if (is.null(blankSpace)) {
    return(NULL)
  }
  if (length(blankSpace) != 4) {
    rlang::abort("blankSpace must contain four integers: top, left, bottom, right.")
  }
  paste(as.integer(blankSpace), collapse = ",")
}


.writeVoiceConfigFile <- function(entries) {
  configPath <- tempfile(fileext = ".voice")
  lines <- character()

  for (entry in entries) {
    key <- entry[[1]]
    value <- entry[[2]]
    if (is.null(value)) {
      next
    }
    if (is.character(value) && length(value) == 1) {
      lines <- c(lines, paste0("$", key, "=", value))
    } else {
      lines <- c(lines, paste0("$", key, "="), as.character(value))
    }
  }

  writeLines(lines, configPath, useBytes = TRUE)
  .normalizePathForJava(configPath, mustWork = FALSE)
}


.createModernTreeViewConfigFile <- function(
  treePath = NA_character_,
  newickText = NULL,
  layout = NULL,
  leafLabel = TRUE,
  title = NULL,
  reverseAxis = FALSE,
  blankSpace = NULL,
  nodeVisualConfigPath = NULL
) {
  resolvedTreePath <- .materializeTreeInput(treePath = treePath, newickText = newickText)
  entries <- list(
    list("input.nwk.path", resolvedTreePath),
    list("layout.initial", layout),
    list("leaf.show.label", .voiceBool(leafLabel)),
    list("tree.title.string", title),
    list("tree.need.reverse.axis", .voiceBool(reverseAxis)),
    list("layout.blank.space", .normalizeBlankSpace(blankSpace)),
    list(
      "advanced.node.visual.config",
      if (is.null(nodeVisualConfigPath)) NULL else .normalizePathForJava(nodeVisualConfigPath, mustWork = FALSE)
    )
  )
  .writeVoiceConfigFile(entries)
}


.createPathwayFamilyBrowserConfigFile <- function(
  treePath = NA_character_,
  newickText = NULL,
  componentCounts = NULL,
  speciesInfo = NULL,
  speciesTraits = NULL,
  galleryPaths = NULL,
  layout = NULL,
  leafLabel = TRUE,
  title = NULL,
  reverseAxis = FALSE,
  blankSpace = NULL,
  nodeVisualConfigPath = NULL
) {
  resolvedTreePath <- .materializeTreeInput(treePath = treePath, newickText = newickText)
  entries <- list(
    list("input.nwk.path", resolvedTreePath),
    list("pathway.gallery.figure.paths", .normalizeGalleryPaths(galleryPaths)),
    list("pathway.species.info.path", .materializeTableInput(speciesInfo)),
    list("pathway.component.counts.path", .materializeTableInput(componentCounts)),
    list("species.traits.path", .materializeTableInput(speciesTraits)),
    list("layout.initial", layout),
    list("leaf.show.label", .voiceBool(leafLabel)),
    list("tree.title.string", title),
    list("tree.need.reverse.axis", .voiceBool(reverseAxis)),
    list("layout.blank.space", .normalizeBlankSpace(blankSpace)),
    list(
      "advanced.node.visual.config",
      if (is.null(nodeVisualConfigPath)) NULL else .normalizePathForJava(nodeVisualConfigPath, mustWork = FALSE)
    )
  )
  .writeVoiceConfigFile(entries)
}


#' Launch the eGPS desktop and return the bridge instance.
#'
#' @return The Java bridge object used by R4eGPS.
#' @export
launchEGPSDesktop <- function() {
  bridgeInstance <- .getBridgeInstance()
  words <- rJava::.jcall(bridgeInstance, "S", "launchDesktop")
  message(words)
  bridgeInstance
}


#' Launch eGPS from R using the configured runtime.
#'
#' @param programPath Optional runtime path kept for backward compatibility.
#'
#' @return The Java bridge object used by R4eGPS.
#' @export
launchEGPS_withinR <- function(programPath = NA_character_) {
  if (!is.na(programPath) && nzchar(programPath)) {
    configureEGPSSourceRuntime(programPath)
  }
  launchEGPSDesktop()
}


#' Open Modern Tree View from a config file.
#'
#' @param configPath A VOICE config file path.
#'
#' @return Invisibly returns the Java bridge instance.
#' @export
openModernTreeViewFromConfig <- function(configPath) {
  bridgeInstance <- .getBridgeInstance()
  rJava::.jcall(
    bridgeInstance,
    "V",
    "openModernTreeView",
    .normalizePathForJava(configPath, mustWork = TRUE)
  )
  invisible(bridgeInstance)
}


#' Open Modern Tree View from R objects or file paths.
#'
#' @param treePath Path to a Newick tree file.
#' @param newickText Raw Newick text. Use this instead of `treePath`.
#' @param layout Optional eGPS layout keyword such as `RECTANGULAR` or `CIRCULAR`.
#' @param leafLabel Whether to display leaf labels.
#' @param title Optional bottom title.
#' @param reverseAxis Whether to reverse the axis bar.
#' @param blankSpace Optional integer vector of length 4: top, left, bottom, right.
#' @param nodeVisualConfigPath Optional TSV annotation config path.
#'
#' @return Invisibly returns the generated config path.
#' @export
openModernTreeView <- function(
  treePath = NA_character_,
  newickText = NULL,
  layout = NULL,
  leafLabel = TRUE,
  title = NULL,
  reverseAxis = FALSE,
  blankSpace = NULL,
  nodeVisualConfigPath = NULL
) {
  configPath <- .createModernTreeViewConfigFile(
    treePath = treePath,
    newickText = newickText,
    layout = layout,
    leafLabel = leafLabel,
    title = title,
    reverseAxis = reverseAxis,
    blankSpace = blankSpace,
    nodeVisualConfigPath = nodeVisualConfigPath
  )
  openModernTreeViewFromConfig(configPath)
  invisible(configPath)
}


#' Open Pathway Family Browser from a config file.
#'
#' @param configPath A VOICE config file path.
#'
#' @return Invisibly returns the Java bridge instance.
#' @export
openPathwayFamilyBrowserFromConfig <- function(configPath) {
  bridgeInstance <- .getBridgeInstance()
  rJava::.jcall(
    bridgeInstance,
    "V",
    "openPathwayFamilyBrowser",
    .normalizePathForJava(configPath, mustWork = TRUE)
  )
  invisible(bridgeInstance)
}


#' Open Pathway Family Browser from R objects or file paths.
#'
#' @param treePath Path to a Newick tree file.
#' @param newickText Raw Newick text. Use this instead of `treePath`.
#' @param componentCounts A data.frame or path for pathway component counts.
#' @param speciesInfo A data.frame or path for species info.
#' @param speciesTraits A data.frame or path for species traits.
#' @param galleryPaths A character vector of pathway gallery files.
#' @param layout Optional eGPS layout keyword.
#' @param leafLabel Whether to display leaf labels.
#' @param title Optional bottom title.
#' @param reverseAxis Whether to reverse the axis bar.
#' @param blankSpace Optional integer vector of length 4: top, left, bottom, right.
#' @param nodeVisualConfigPath Optional TSV annotation config path.
#'
#' @return Invisibly returns the generated config path.
#' @export
openPathwayFamilyBrowser <- function(
  treePath = NA_character_,
  newickText = NULL,
  componentCounts = NULL,
  speciesInfo = NULL,
  speciesTraits = NULL,
  galleryPaths = NULL,
  layout = NULL,
  leafLabel = TRUE,
  title = NULL,
  reverseAxis = FALSE,
  blankSpace = NULL,
  nodeVisualConfigPath = NULL
) {
  configPath <- .createPathwayFamilyBrowserConfigFile(
    treePath = treePath,
    newickText = newickText,
    componentCounts = componentCounts,
    speciesInfo = speciesInfo,
    speciesTraits = speciesTraits,
    galleryPaths = galleryPaths,
    layout = layout,
    leafLabel = leafLabel,
    title = title,
    reverseAxis = reverseAxis,
    blankSpace = blankSpace,
    nodeVisualConfigPath = nodeVisualConfigPath
  )
  openPathwayFamilyBrowserFromConfig(configPath)
  invisible(configPath)
}


#' Set library and launch JVM against the configured runtime.
#'
#' @return The effective Java classpath entries.
#' @export
setLib_and_launchJVM <- function() {
  runtimeLayout <- .resolveRuntimeLayout(quiet = FALSE)
  javaPath <- .getConfiguredJavaPath(runtimeLayout)
  if (!is.na(javaPath)) {
    Sys.setenv(JAVA_HOME = .inferJavaHome(javaPath))
  }

  .requireRJava()
  javaParameters <- .getJavaParametersForRuntime(runtimeLayout$root)

  if (!rJava::.jvmState()$initialized) {
    rJava::.jinit(parameters = javaParameters)
  }
  rJava::.jaddClassPath(runtimeLayout$classPathEntries)

  invisible(rJava::.jclassPath())
}


checkJarLibAvaliable <- function(programPath = NA_character_) {
  if (!is.na(programPath) && nzchar(programPath)) {
    configureEGPSSourceRuntime(programPath)
  }

  runtimeLayout <- .resolveRuntimeLayout(quiet = TRUE)
  if (is.null(runtimeLayout)) {
    return(FALSE)
  }

  requiredPaths <- c(runtimeLayout$argsPath, runtimeLayout$classPathEntries)
  all(file.exists(requiredPaths))
}
