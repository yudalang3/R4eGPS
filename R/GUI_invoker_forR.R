#' Correlation Visualization with the expression profile
#'
#' @param df the data frame
#' @param expMatrixCol the col names of the expression matrix, only the first 'name' column is needed.
#' @param cat1Col the col names of the category one: name, cat1, or color(optional)
#' @param cat2Col the col names of the category two: name, cat2 and value
#' @param egps the eGPS Java instance
#'
#' @return no return
#' @export
#'
#' @examples
#' \dontrun{
#'
#' egps <- launchEGPS_withinR()
#'
#' compsLength <- 10
#' sampleSize <- 8
#' gNames <- paste0('Gene', 1:compsLength)
#' simulatedData <- setNames(
#'   as.data.frame(replicate(sampleSize, runif(compsLength, 0, sampleSize))),
#'   paste0('S', 1:sampleSize)
#' )
#' df <- data.frame(name = gNames, simulatedData,
#'                       cat1 = rep(c("Cat1","Cat2","Cat3"), each = 3, length.out = compsLength),
#'                       cat2 = rep(c("Cat1","Cat2","Cat3"), each = 4, length.out = compsLength),
#'                       value = 1)
#' # make sure the column names are matched
#' correlationVis_expressionProfile(egps, df,expMatrixCol = c("name"),
#'                                  cat1Col = c("name", "cat1"),
#'                                  cat2Col = c("name", "cat2", "value"))
#'
#' }
correlationVis_expressionProfile <- function(egps,
                                             df,
                                             expMatrixCol = c("name"),
                                             cat1Col = c("name", "cat1"),
                                             cat2Col = c("name", "cat2", "value")) {
  initializeJVM4eGPS()
  ll <- list(expMatrixCol = expMatrixCol,
             cat1Col = cat1Col,
             cat2Col = cat2Col)
  jsonStr <- list2jsonStr(ll)
  temp.out <- tempfile(fileext = ".txt")

  writeDataFrameToTsv(df, path = temp.out)

  tryCatch(
    expr = {
      rJava::.jcall(egps, "V", "correlationVis", temp.out, jsonStr)
    },
    error = getErrorFun(),
    finally = {
      # on.exit(unlink(temp.out))
      # Java programe will delete the file
    }
  )
}
