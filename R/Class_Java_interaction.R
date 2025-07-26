#' Launch eGPS2 GUI desktop in R
#'
#' If you want to see the JVM parameters, using options(java.parameters = c("-Xmx4G"))
#'
#'
#' @param programPath the eGPS2 software program path, the R4eGPS will remember the config parameter. This is setting for the first time, for the second time or later, this is not need to do. You can also set via 'setGlobalVars(list(eGPS_software_path = "/path/to/software"))'
#'
#' @return the JAVA object of eGPS2
#' @export
#'
#' @examples
#' \dontrun{
#' # This is for the first time
#' egps <- launchEGPS_withinR(programPath = '/path/to/egps/')
#' # routine use
#' egps <- launchEGPS_withinR()
#' egps$callTest("Hello eGPS in R!")
#' }
launchEGPS_withinR <- function(programPath = NA_character_) {
  if (!checkJarLibAvaliable(programPath)) {
    return(invisible())
  }
  setLib_and_launchJVM()

  launchClass <- "module.RlangInterfaceEGPS"
  tryCatch(
    expr = {
      instance <- .jnew(launchClass)
      words <- .jcall(obj = instance,
                      returnSig = "S",
                      method = "launch")
      print(words);
    },
    error = getErrorFun()
  )


  return(instance)

}


#' Set library and launch JVM
#'
#' @return the lib paths
#' @export
#'
#' @examples
#' setLib_and_launchJVM()
setLib_and_launchJVM <- function() {
  # 使用require函数
  if (!require("rJava", character.only = TRUE)) {
    stop(
      "Please install the rJava package first.\nYou can install via install.package('rJava')"
    )
  }

  library(rJava)
  .jinit()
  # 要先启动再添加
  jarFile <- file.path(getGlobalVars()[[eGPS_software_path_key]] , 'eGPS_lib')
  .jaddClassPath(list.files(jarFile, full.names = T))

  invisible(.jclassPath())
}

checkJarLibAvaliable <- function(programPath = NA_character_) {
  if (!is.na(programPath)) {
    if (file.exists(programPath) &&
        file.info(programPath)$isdir) {
      vars <- getGlobalVars()
      if (is.null(vars)) {
        vars <- list()
      }
      vars[[eGPS_software_path_key]] <- programPath
      setGlobalVars(vars)
    }
  }

  vars <- getGlobalVars()

  if (is.null(vars)) {
    message(
      "Please set the directory of the eGPS software first: setGlobalVars(list(eGPS_software_path = \"/path/to/software\")) "
    )
    return(F)
  }

  eGPS_software_path <- vars[[eGPS_software_path_key]]

  if (is.null(eGPS_software_path)) {
    message(
      "Please set the directory of the eGPS software first: setGlobalVars(list(eGPS_software_path = \"/path/to/software\")) "
    )
    return(F)
  } else {
    if (file.exists(eGPS_software_path) &&
        file.info(eGPS_software_path)$isdir) {

    } else {
      errorMsg <- paste0("The already setting eGPS software path is not a exist dir. ",
                         eGPS_software_path)
      message(errorMsg)
      return(F)
    }
  }

  return(T)
}
