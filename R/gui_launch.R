# GUI launch functions for eGPS desktop, Modern Tree View, and Pathway Family Browser.


.getBridgeInstance <- function() {
  initializeJVM4eGPS()
  rJava::.jnew("api.rpython.RlangInterfaceEGPS")
}


#' Launch the eGPS desktop and return the bridge instance.
#'
#' @return The Java bridge object used by R4eGPS.
#' @export
launchEGPSDesktop <- function() {
  bridgeInstance <- .getBridgeInstance()
  words <- rJava::.jcall(bridgeInstance, "S", "launchDesktop")
  message(words)
  bridgeInstance
}


#' Launch eGPS from R using the configured runtime.
#'
#' @param programPath Optional runtime path kept for backward compatibility.
#'
#' @return The Java bridge object used by R4eGPS.
#' @export
launchEGPS_withinR <- function(programPath = NA_character_) {
  if (!is.na(programPath) && nzchar(programPath)) {
    configureEGPSSourceRuntime(programPath)
  }
  launchEGPSDesktop()
}


#' Open Modern Tree View from a config file.
#'
#' @param configPath A VOICE config file path.
#'
#' @return Invisibly returns the Java bridge instance.
#' @export
openModernTreeViewFromConfig <- function(configPath) {
  bridgeInstance <- .getBridgeInstance()
  rJava::.jcall(
    bridgeInstance,
    "V",
    "openModernTreeView",
    .normalizePathForJava(configPath, mustWork = TRUE)
  )
  invisible(bridgeInstance)
}


#' Open Modern Tree View from R objects or file paths.
#'
#' @param treePath Path to a Newick tree file.
#' @param newickText Raw Newick text. Use this instead of `treePath`.
#' @param layout Optional eGPS layout keyword such as `RECTANGULAR` or `CIRCULAR`.
#' @param leafLabel Whether to display leaf labels.
#' @param title Optional bottom title.
#' @param reverseAxis Whether to reverse the axis bar.
#' @param blankSpace Optional integer vector of length 4: top, left, bottom, right.
#' @param nodeVisualConfigPath Optional TSV annotation config path.
#'
#' @return Invisibly returns the generated config path.
#' @export
openModernTreeView <- function(
  treePath = NA_character_,
  newickText = NULL,
  layout = NULL,
  leafLabel = TRUE,
  title = NULL,
  reverseAxis = FALSE,
  blankSpace = NULL,
  nodeVisualConfigPath = NULL
) {
  configPath <- .createModernTreeViewConfigFile(
    treePath = treePath,
    newickText = newickText,
    layout = layout,
    leafLabel = leafLabel,
    title = title,
    reverseAxis = reverseAxis,
    blankSpace = blankSpace,
    nodeVisualConfigPath = nodeVisualConfigPath
  )
  openModernTreeViewFromConfig(configPath)
  invisible(configPath)
}


#' Open Pathway Family Browser from a config file.
#'
#' @param configPath A VOICE config file path.
#'
#' @return Invisibly returns the Java bridge instance.
#' @export
openPathwayFamilyBrowserFromConfig <- function(configPath) {
  bridgeInstance <- .getBridgeInstance()
  rJava::.jcall(
    bridgeInstance,
    "V",
    "openPathwayFamilyBrowser",
    .normalizePathForJava(configPath, mustWork = TRUE)
  )
  invisible(bridgeInstance)
}


#' Open Pathway Family Browser from R objects or file paths.
#'
#' @param treePath Path to a Newick tree file.
#' @param newickText Raw Newick text. Use this instead of `treePath`.
#' @param componentCounts A data.frame or path for pathway component counts.
#' @param speciesInfo A data.frame or path for species info.
#' @param speciesTraits A data.frame or path for species traits.
#' @param galleryPaths A character vector of pathway gallery files.
#' @param layout Optional eGPS layout keyword.
#' @param leafLabel Whether to display leaf labels.
#' @param title Optional bottom title.
#' @param reverseAxis Whether to reverse the axis bar.
#' @param blankSpace Optional integer vector of length 4: top, left, bottom, right.
#' @param nodeVisualConfigPath Optional TSV annotation config path.
#'
#' @return Invisibly returns the generated config path.
#' @export
openPathwayFamilyBrowser <- function(
  treePath = NA_character_,
  newickText = NULL,
  componentCounts = NULL,
  speciesInfo = NULL,
  speciesTraits = NULL,
  galleryPaths = NULL,
  layout = NULL,
  leafLabel = TRUE,
  title = NULL,
  reverseAxis = FALSE,
  blankSpace = NULL,
  nodeVisualConfigPath = NULL
) {
  configPath <- .createPathwayFamilyBrowserConfigFile(
    treePath = treePath,
    newickText = newickText,
    componentCounts = componentCounts,
    speciesInfo = speciesInfo,
    speciesTraits = speciesTraits,
    galleryPaths = galleryPaths,
    layout = layout,
    leafLabel = leafLabel,
    title = title,
    reverseAxis = reverseAxis,
    blankSpace = blankSpace,
    nodeVisualConfigPath = nodeVisualConfigPath
  )
  openPathwayFamilyBrowserFromConfig(configPath)
  invisible(configPath)
}
