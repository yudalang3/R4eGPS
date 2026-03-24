#' With importing the tree_path and the onlyLeaf parameters, return the names array.
#'
#' @param tree_path The phylogenetic tree path
#' @param targetHTU NULL for the root node, else input the internal node name
#' @param getOTU whether get the OTU names
#' @param getHTU whether get the HTU names
#'
#' @return the string vecotr of names.
#' @export
#'
#' @examples
#' \dontrun{
#' ## get the leaf names:
#' evoltre_getNodeNames('path/to/tree.nwk' ,  getOTU = T, getHTU = F);
#' ## get the leaf names of certain internal node
#' evoltre_getNodeNames('path/to/tree.nwk' , targetHTU = 'name1', getOTU = T, getHTU = F);
#' }
#'
evoltre_getNodeNames <- function(tree_path, targetHTU = NULL , getOTU = TRUE, getHTU = FALSE) {
  if (rlang::is_missing(tree_path)) {
    rlang::abort('Please input the tree_path argument.')
  }

  initializeJVM4eGPS()
  launchClass <- "api.rpython.API4R"
  if (is.null(targetHTU)) {
    targetHTU <- rJava::.jnull("java.lang.String") # 显式传递 Java 的 null
  }
  javaResult <- tryCatch(
    expr = {
      instance <- rJava::.jnew(launchClass)
      rJava::.jcall(instance,
                    "[Ljava/lang/String;",
                    "extractNodeNames",
                    .normalizePathForJava(tree_path, mustWork = FALSE),
                    targetHTU,
                    getOTU,
                    getHTU)
    },
    error = function(e) {
      rlang::abort(conditionMessage(e))
    }
  )
  return(javaResult)
}
