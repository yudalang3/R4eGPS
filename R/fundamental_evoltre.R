#' With importing the tree_path and the onlyLeaf parameters, return the names array.
#'
#' @param treePath The phylogenetic tree path
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
evoltre_getNodeNames <- function(treePath, targetHTU = NULL, getOTU = TRUE, getHTU = FALSE) {
  if (rlang::is_missing(treePath)) {
    rlang::abort('Please input the treePath argument.')
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
                    .normalizePathForJava(treePath, mustWork = FALSE),
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
