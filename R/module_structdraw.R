



#' Draw the multi genes struct
#'
#' @param list list of the ploted views
#' @param width the width of the displayed form view
#' @param height the height of the displayed form view
#' @param gHeight the height of each gene
#'
#' @return no return
#' @export
#'
#' @examples
#' \dontrun{
#' list1 <- list(
#' gene1 = list(length = 250, start = c(1,10,101,200), end = c(8, 56, 152, 230), color = c("#E63946", "#457B9D", "#2A9D8F", "#F4A261")),
#'  gene2 = list(length = 350,start = c(1,180,210,261), end = c(150, 200, 250, 300), color = c("#E63946", "#457B9D", "#2A9D8F", "#F4A261")),
#'  gene3 = list(length = 300,start = c(51,101,200), end = c(100,150,231), color = c("#2A9D8F", "#F4A261", "#1D3557"))
#' )
#' list2 <- list(
#'  gene1 = list(length = 100, start = 1, end = 50, color = c("#E63946")),
#'  gene3 = list(length = 300,start = c(51,101), end = c(100,150), color = c("#2A9D8F", "#F4A261"))
#' )
#' R4eGPS::structDraw_multi_genes(list1)
#' }
structDraw_multi_genes <- function(list,
                                   width = 800,
                                   height = 500,
                                   gHeight = 50) {
  if (rlang::is_missing(list)) {
    rlang::abort('Please input the list argument.')
  }

  initializeJVM4eGPS()
  width <- as.integer(width)
  height <- as.integer(height)
  gHeight <- as.integer(gHeight)

  jsonStr <- jsonlite::toJSON(list)
  stringJavaObject <- rJava::.jnew("java/lang/String", jsonStr)

  launchClass <- "egps2.module.structdraw.API4R"
  tryCatch(
    expr = {
      instance <- rJava::.jnew(launchClass)
      rJava::.jcall(instance,
                    "V",
                    "draw_multiple_genes",
                    stringJavaObject,
                    width,
                    height,
                    gHeight)
    },
    error = getErrorFun()
  )
}
