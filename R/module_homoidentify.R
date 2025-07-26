
#' Parse the hmmer domtbl output to tsv file
#'
#' @param hmmerDomtbl the path of hmmer domtbl
#' @param outputPath  the path of output file
#'
#' @return nothing
#' @export
#'
hmmer_domtbl2tsv <- function(hmmerDomtbl, outputPath) {
  if (rlang::is_missing(hmmerDomtbl) || rlang::is_missing(outputPath)) {
    rlang::abort('Please input the fasta file path and the input entries.')
  }
  initializeJVM4eGPS()

  launchClass <- "module.homoidentify.totsv.API4R"
  tryCatch(
    expr ={
      instance <- rJava::.jnew(launchClass)
      rJava::.jcall(instance, "V", "domtbl_output_to_tsv", hmmerDomtbl , outputPath)
    },
    error = getErrorFun()
  )
}
