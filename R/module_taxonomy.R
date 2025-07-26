#' Get the ranked lineages of a species
#'
#' @param filePath the NCBI ranked lineages dump file
#' @param entries the taxon ids
#'
#' @returns the string double array
#' @export
#'
#' @examples
#' taxonomy_getRankedLineages("path", c(1,2))
taxonomy_getRankedLineages <- function(filePath,
                                     entries) {
  if (rlang::is_missing(filePath) || rlang::is_missing(entries)) {
    rlang::abort('Please input the ranked lineages file path and the input entries.')
  }

  entries <- as.integer(entries)

  initializeJVM4eGPS()


  launchClass <- "ncbi.taxonomy.API4R"
  tryCatch(expr = {
    instance <- rJava::.jnew(launchClass)
    ret <- rJava::.jcall(
      instance,
      "[S",
      "getRankedLineages",
      filePath,
      .jarray(entries)
    )
  }, error = getErrorFun())


  # 使用 strsplit 分割字符串
  split_strings <- strsplit(ret, "\t")

  # 将列表转换为 data.frame
  df <- do.call(rbind, lapply(split_strings, function(x)
    as.data.frame(t(x), stringsAsFactors = FALSE)))

  # 设置列名
  colnames(df) <- c(
    "TaxName",
    "Species",
    "Genus",
    "Family",
    "Order",
    "Class",
    "Phylum",
    "Kingdom",
    "SuperKingdom"
  )

  return(df)

}
