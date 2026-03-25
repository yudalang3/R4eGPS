storage_file_path <- file.path(Sys.getenv("HOME"), ".R4eGPS.package.vars.rds")
egps_repo_root_key <- "egps_repo_root"
java_path_key <- "java_path"
eGPS_software_path_key <- 'eGPS_software_path'
# storage_file_path <- tools::R_user_dir("tryR.package.vars.rds")
# Not work on Windows
#' .onLoad function
#'
#' This function is called automatically when the package is loaded.
#'
#' @param libname the lib name
#' @param pkgname the package name
.onLoad <- function(libname, pkgname) {
  maxHeap <- getOption("R4eGPS.max_heap", Sys.getenv("R4EGPS_MAX_HEAP", "4g"))
  options(
    java.parameters = unique(c(
      getOption("java.parameters", character()),
      "-Dfile.encoding=UTF-8",
      "-Dstdout.encoding=UTF-8",
      "-Dstderr.encoding=UTF-8",
      paste0("-Xmx", maxHeap)
    ))
  )
}


#' set The global Vars.
#' Current support is:
#'
#' 'egps_repo_root': the persisted eGPS runtime root, usually the installation root
#' 'java_path': optional path to java or jvm.dll, defaulting to the bundled JRE when available
#' 'eGPS_software_path': legacy key retained for backward compatibility
#'
#' @param varList a named vector with string key-values.
#'
#' @return no return
#' @export
#' @importFrom utils modifyList
#'
#' @examples
#' \dontrun{
#'
#' setGlobalVars( list( eGPS_software_path = '/your/path/dir') )
#' vars <- getGlobalVars();vars[['eGPS_software_path']] <- "/new/path/dir"
#'
#' }
setGlobalVars <- function(varList) {
  if (rlang::is_empty(varList)) {
    rlang::abort(message = "Please input validate variable.")
  }

  newVars <- as.list(varList)
  var_names <- names(newVars)
  if (is.null(var_names) || any(!nzchar(var_names))) {
    rlang::abort(message = "Please read the help of this function.")
  }

  existingVars <- if (file.exists(storage_file_path)) {
    as.list(readRDS(storage_file_path))
  } else {
    list()
  }

  mergedVars <- modifyList(existingVars, newVars)
  saveRDS(mergedVars, file = storage_file_path)
}

#' Get the global values.
#' You may wonder Can we set the global values through the returned env. object?
#' No.
#' (1) will not persist store in your desk.
#' (2) Temporary usage is enough setGlobalVars(NULL) to save.
#'
#' @return the env to store the values.
#' @export
#'
#' @examples
#' getGlobalVars()
getGlobalVars <- function() {
  if (file.exists(storage_file_path)) {
    storedVars <- readRDS(storage_file_path)
    if (is.environment(storedVars)) {
      return(as.list(storedVars, all.names = TRUE))
    }
    return(as.list(storedVars))
  }
  NULL
}


.Last.lib <- function(libpath) {
  # The cleanup operation performed when the package is uninstalled
  message(" Uninstall package and perform cleanup..." )

  # success <- file.remove(storage_file_path)
  # if (!success) {
  #   message(" Remove the R4eGPS configuration file in: ",storage_file_path )
  # }
  # Example: Releasing resources, closing connections, etc
  # Close database connection, free memory, or other related cleanup
}
