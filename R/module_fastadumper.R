#' Obtain sequences from the fasta file
#'
#' Run example
#' # entry = c("gene1","gene2","gene2"))
#' # fastadumper_partialMatch(fastaPath = "subject.fa",entries = entry, outPath = "out.fa")
#'
#' @param fastaPath the input path of the fasta
#' @param entries the string vector of the sequence to extract
#' @param outPath the output path
#' @param keepSearch whether repeat search for the entries
#'
#' @return nothing
#' @export
#'
fastadumper_partialMatch <- function(fastaPath, entries, outPath = 'extracted.seq.fa', keepSearch = F) {
  if (rlang::is_missing(fastaPath) || rlang::is_missing(entries)) {
    rlang::abort('Please input the fasta file path and the input entries.')
  }
  initializeJVM4eGPS();

  launchClass <- "egps2.module.fastadumper.extractpartial.API4R"
  tryCatch(
    expr ={
      instance <- rJava::.jnew(launchClass)
      rJava::.jcall(instance, "V", "fastadumper_partialMatch",fastaPath, entries, outPath,keepSearch)
    },
    error = getErrorFun()
  )
}

