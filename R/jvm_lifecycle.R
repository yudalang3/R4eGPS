# JVM initialization, classpath management, and runtime configuration.


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
        "Install it in", shQuote(file.path(R.home("bin"), "R.exe")),
        "or via install.packages('rJava') before calling GUI functions."
      )
    )
  }
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


#' Check whether the eGPS jar libraries are available.
#'
#' @param programPath Optional runtime path.
#'
#' @return TRUE if all required files exist, FALSE otherwise.
checkJarLibAvailable <- function(programPath = NA_character_) {
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
