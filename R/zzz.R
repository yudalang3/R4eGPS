storage_file_path <- file.path(Sys.getenv("HOME"), ".R4eGPS.package.vars.rds")
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
  # Let user setting the java.para
  # message("The libname is ", libname, ". The pkgname is ", pkgname)
  # message("This package is for YDL personal use...")
  options(
    java.parameters = c(
      "-Dfile.encoding=UTF-8",
      "-Dstdout.encoding=UTF-8",
      "-Dstderr.encoding=UTF-8" ,
      "-Xmx2g"
    )
  )

  if (checkJarLibAvaliable()) {
    setLib_and_launchJVM();
  }

}


#' set The global Vars.
#' Current support is:
#'
#' 'eGPS_software_path': the eGPS jars lib path, for example: "C:/Users/yudal/Documents/project/eGPS2/eGPS_v2_windows_64bit/eGPS_lib"
#'
#' @param varList a named vector with string key-values.
#'
#' @return no return
#' @export
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

  var_names <- names(varList)
  if (length(var_names) != length(varList)) {
    rlang::abort(message = "Please read the help of this function.")
  }
  varList <- as.list(varList)
  R4eGPS_persisting_Vars <- new.env(parent = emptyenv())
  lapply(seq_along(varList), function(i) {
    nm <- var_names[i]  # 获取对应的变量名称
    x <- varList[[i]]   # 获取对应的变量值
    R4eGPS_persisting_Vars[[nm]] <<- x
  })

  saveRDS(R4eGPS_persisting_Vars, file = storage_file_path);
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
  if( file.exists(storage_file_path) ){
    return(readRDS(storage_file_path))
  }else {
   return(NULL)
  }
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
