# VOICE configuration file generation for eGPS GUI components.


.voiceBool <- function(value) {
  if (isTRUE(value)) {
    return("T")
  }
  "F"
}


.materializeTreeInput <- function(treePath = NA_character_, newickText = NULL) {
  hasTreePath <- !is.na(treePath) && nzchar(treePath)
  hasNewickText <- !is.null(newickText) && nzchar(newickText)
  if (hasTreePath == hasNewickText) {
    rlang::abort("Provide exactly one of treePath or newickText.")
  }

  if (hasTreePath) {
    return(.normalizePathForJava(treePath, mustWork = FALSE))
  }

  tempTreePath <- tempfile(fileext = ".nwk")
  writeLines(newickText, tempTreePath, useBytes = TRUE)
  .normalizePathForJava(tempTreePath, mustWork = FALSE)
}


.materializeTableInput <- function(value) {
  if (is.null(value)) {
    return("False")
  }
  if (is.data.frame(value)) {
    if (!"Name" %in% colnames(value)) {
      rlang::abort("Data frame inputs must contain a 'Name' column.")
    }
    tempPath <- tempfile(fileext = ".tsv")
    writeDataFrameToTsv(value, tempPath)
    return(.normalizePathForJava(tempPath, mustWork = FALSE))
  }
  .normalizePathForJava(value, mustWork = FALSE)
}


.normalizeGalleryPaths <- function(galleryPaths) {
  if (is.null(galleryPaths)) {
    return(NULL)
  }
  vapply(galleryPaths, .normalizePathForJava, character(1), mustWork = FALSE)
}


.normalizeBlankSpace <- function(blankSpace) {
  if (is.null(blankSpace)) {
    return(NULL)
  }
  if (length(blankSpace) != 4) {
    rlang::abort("blankSpace must contain four integers: top, left, bottom, right.")
  }
  paste(as.integer(blankSpace), collapse = ",")
}


.writeVoiceConfigFile <- function(entries) {
  configPath <- tempfile(fileext = ".voice")
  lines <- character()

  for (entry in entries) {
    key <- entry[[1]]
    value <- entry[[2]]
    if (is.null(value)) {
      next
    }
    if (is.character(value) && length(value) == 1) {
      lines <- c(lines, paste0("$", key, "=", value))
    } else {
      lines <- c(lines, paste0("$", key, "="), as.character(value))
    }
  }

  writeLines(lines, configPath, useBytes = TRUE)
  .normalizePathForJava(configPath, mustWork = FALSE)
}


.createModernTreeViewConfigFile <- function(
  treePath = NA_character_,
  newickText = NULL,
  layout = NULL,
  leafLabel = TRUE,
  title = NULL,
  reverseAxis = FALSE,
  blankSpace = NULL,
  nodeVisualConfigPath = NULL
) {
  resolvedTreePath <- .materializeTreeInput(treePath = treePath, newickText = newickText)
  entries <- list(
    list("input.nwk.path", resolvedTreePath),
    list("layout.initial", layout),
    list("leaf.show.label", .voiceBool(leafLabel)),
    list("tree.title.string", title),
    list("tree.need.reverse.axis", .voiceBool(reverseAxis)),
    list("layout.blank.space", .normalizeBlankSpace(blankSpace)),
    list(
      "advanced.node.visual.config",
      if (is.null(nodeVisualConfigPath)) NULL else .normalizePathForJava(nodeVisualConfigPath, mustWork = FALSE)
    )
  )
  .writeVoiceConfigFile(entries)
}


.createPathwayFamilyBrowserConfigFile <- function(
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
  resolvedTreePath <- .materializeTreeInput(treePath = treePath, newickText = newickText)
  entries <- list(
    list("input.nwk.path", resolvedTreePath),
    list("pathway.gallery.figure.paths", .normalizeGalleryPaths(galleryPaths)),
    list("pathway.species.info.path", .materializeTableInput(speciesInfo)),
    list("pathway.component.counts.path", .materializeTableInput(componentCounts)),
    list("species.traits.path", .materializeTableInput(speciesTraits)),
    list("layout.initial", layout),
    list("leaf.show.label", .voiceBool(leafLabel)),
    list("tree.title.string", title),
    list("tree.need.reverse.axis", .voiceBool(reverseAxis)),
    list("layout.blank.space", .normalizeBlankSpace(blankSpace)),
    list(
      "advanced.node.visual.config",
      if (is.null(nodeVisualConfigPath)) NULL else .normalizePathForJava(nodeVisualConfigPath, mustWork = FALSE)
    )
  )
  .writeVoiceConfigFile(entries)
}
