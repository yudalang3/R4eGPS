#' Convert the R object, usually the list inside data.frames, to JSON string with some customized configurations/rules.
#'
#' @param ll a list, usually with data.frame inside it
#'
#' @return the JSON string
#'
list2jsonStr <- function(ll) {
  if (is.null(ll)) {
    stop("Please input values for parameter ll.");
  }
  if (!is.list(ll)) {
    stop("Parameter ll must be a list.");
  }

  jsonStr <- jsonlite::toJSON(ll, dataframe = 'columns')
  return(jsonStr)
}



#' Function as its name.
#' how to use: writeDataFrameToTsv(data.frame(), "/output/path")
#'
#' importFrom("utils", "write.table")
#' @param df the data.frame
#' @param path the output path
#'
#' @return nothing
#'
writeDataFrameToTsv <- function(df, path) {
  write.table(df, file = path, quote = F, row.names = F, sep = "\t")
}


#' Initialize the JVM, if the JVM is already launched, do nothing.
#'
#' @return nothing, error will throw if the command not meet.
#'
initializeJVM4eGPS <- function() {
  if (!rJava::.jvmState()$initialized) {
    if (checkJarLibAvaliable()) {
      setLib_and_launchJVM()
    }else {
      rlang::abort("Sorry, please confige the eGPS first.")
    }
  }
}

#' Run for a test.
#'
#' @return nothing
#' @export
#'
runTest <- function() {
  initializeJVM4eGPS();
  launchClass <- "module.fastadumper.extractpartial.API4R"
  instance <- rJava::.jnew(launchClass)
  rJava::.jcall(instance, "V", "test4type",letters, 1:10)
}


#' get the error fun for catch error.
#'
getErrorFun <- function() {
  error = function(e) {
    message("Running error:\nLets look at the condition object:")
    str(e)
  }
  return(error)
}
