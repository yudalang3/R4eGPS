#' With importing the tree_path and the onlyLeaf parameters, return the names array.
#'
#' @param tree_path The phylogenetic tree path
#' @param onlyLeaf only leaf names or the total names (including internal nodes)
#'
#' @return the string vecotr of names.
#' @export
#'
#' @examples
#' \dontrun{
#' evoltre_getNodeNames('path/to/tree.nwk' ,  onlyLeaf = F);
#' }
#'
evoltre_getNodeNames <- function(tree_path, onlyLeaf = FALSE) {
  if (rlang::is_missing(tree_path)) {
    rlang::abort('Please input the tree_path argument.')
  }

  initializeJVM4eGPS();
  launchClass <- "egps2.module.evoltre.rinterface.API4R"
  tryCatch(
    expr = {
      instance <- rJava::.jnew(launchClass)
      javaResult <- rJava::.jcall(instance,
                                  "[Ljava/lang/String;",
                                  "getNodeNames",
                                  tree_path,
                                  onlyLeaf)
    },
    error = getErrorFun()
  )
  return(javaResult)
}
