#' Convert the R object, usually the list inside data.frames, to JSON string with some customized configurations/rules.
#'
#' @param ll a list, usually with data.frame inside it
#'
#' @return the JSON string
#'
list2jsonStr <- function(ll) {
  if (is.null(ll)) {
    rlang::abort("Please input values for parameter ll.")
  }
  if (!is.list(ll)) {
    rlang::abort("Parameter ll must be a list.")
  }

  jsonStr <- jsonlite::toJSON(ll, dataframe = 'columns')
  return(jsonStr)
}



#' Write a data.frame to a tab-separated file.
#'
#' @param df the data.frame
#' @param path the output path
#'
#' @return nothing
#' @importFrom utils write.table
#'
writeDataFrameToTsv <- function(df, path) {
  write.table(df, file = path, quote = F, row.names = F, sep = "\t")
}


#' Initialize the JVM, if the JVM is already launched, do nothing.
#'
#' @return nothing, error will throw if the command not meet.
#'
initializeJVM4eGPS <- function() {
  setLib_and_launchJVM()
}

#' Run for a test.
#'
#' @return nothing
#' @export
#'
runTest <- function() {
  initializeJVM4eGPS()
  rJava::.jcall(
    "api.rpython.TestJFrame",
    "[B",
    "renderDemoImageAsPng",
    as.integer(160),
    as.integer(120)
  )
}


#' Normalize a file path for Java compatibility.
#'
#' @param path the file path to normalize
#' @param mustWork logical, should the path exist?
#'
#' @return the normalized path with forward slashes
#' @keywords internal
.normalizePathForJava <- function(path, mustWork = TRUE) {
  normalizePath(path, winslash = "/", mustWork = mustWork)
}


#' Coerce stored vars to a list.
#'
#' @param vars the stored vars (list or environment)
#'
#' @return the vars coerced to a list, or NULL
#' @keywords internal
.coerceStoredVars <- function(vars) {
  if (is.null(vars)) {
    return(NULL)
  }
  if (is.environment(vars)) {
    return(as.list(vars, all.names = TRUE))
  }
  as.list(vars)
}
