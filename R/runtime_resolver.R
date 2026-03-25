# Runtime layout detection and resolution for eGPS installations.


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
