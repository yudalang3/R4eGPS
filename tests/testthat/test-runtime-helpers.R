# Runtime helper tests migrated to testthat format.
# These tests verify runtime layout resolution, config file persistence,
# JVM argument parsing, and VOICE configuration generation.

repoRoot <- normalizePath(file.path(getwd(), ".."), winslash = "/", mustWork = TRUE)
r4eGPSRoot <- file.path(repoRoot, "R4eGPS")
bundleRoot <- normalizePath(
  file.path(repoRoot, "..", "..", "eGPS_v2.1_windows_x64_selfTest"),
  winslash = "/", mustWork = TRUE
)
bundleDependencyDir <- file.path(bundleRoot, "dependency-egps")

source(file.path(r4eGPSRoot, "R", "zzz.R"))
source(file.path(r4eGPSRoot, "R", "utils.R"))
source(file.path(r4eGPSRoot, "R", "runtime_resolver.R"))
source(file.path(r4eGPSRoot, "R", "jvm_lifecycle.R"))
source(file.path(r4eGPSRoot, "R", "voice_config.R"))


test_that("configureEGPSSourceRuntime works and checkJarLibAvailable returns TRUE", {
  configureEGPSSourceRuntime(repoRoot)
  expect_true(checkJarLibAvailable())
})


test_that("bundle layout is resolved from dependency-egps directory", {
  bundleLayout <- .resolveRuntimeLayout(bundleDependencyDir)
  expect_identical(bundleLayout$kind, "bundle")
  expect_identical(bundleLayout$root, bundleRoot)
  expect_identical(bundleLayout$argsPath, file.path(bundleRoot, "eGPS2.args"))
  expect_identical(
    bundleLayout$bundledJvmPath,
    file.path(bundleRoot, "jre", "bin", "server", "jvm.dll")
  )
  expect_true(any(grepl("egps-shell-0.0.1.jar$", bundleLayout$classPathEntries)))
})


test_that("interactive prompt resolves to bundle and persists vars", {
  originalStoragePath <- storage_file_path
  originalPromptForRuntimeRoot <- .promptForRuntimeRoot
  originalDiscoverRepoRoot <- .discoverRepoRoot
  testStoragePath <- tempfile(fileext = ".rds")

  on.exit({
    storage_file_path <<- originalStoragePath
    .promptForRuntimeRoot <<- originalPromptForRuntimeRoot
    .discoverRepoRoot <<- originalDiscoverRepoRoot
    if (file.exists(testStoragePath)) file.remove(testStoragePath)
  })

  storage_file_path <<- testStoragePath
  .promptForRuntimeRoot <<- function() bundleDependencyDir
  .discoverRepoRoot <<- function() NA_character_

  promptedLayout <- .resolveRuntimeLayout(quiet = FALSE)
  promptedVars <- getGlobalVars()

  expect_identical(promptedLayout$kind, "bundle")
  expect_identical(promptedLayout$root, bundleRoot)
  expect_identical(promptedVars[[egps_repo_root_key]], bundleRoot)
  expect_identical(
    promptedVars[[java_path_key]],
    file.path(bundleRoot, "jre", "bin", "server", "jvm.dll")
  )
})


test_that("JVM arguments are parsed correctly from eGPS.args", {
  javaArgs <- .parseEGPSArgs(repoRoot)
  expect_true("--add-opens=java.desktop/java.awt=ALL-UNNAMED" %in% javaArgs)
  expect_true("-Dcom.sun.xml.bind.v2.bytecode.ClassTailor.noOptimize" %in% javaArgs)
})


test_that("classpath entries contain expected paths", {
  classPathEntries <- .getRuntimeClassPathEntries(repoRoot)
  expect_true(any(grepl("egps-main\\.gui/out/production/egps-main\\.gui$", classPathEntries)))
  expect_true(any(grepl("egps-pathway\\.evol\\.browser/out/production/egps-pathway\\.evol\\.browser$", classPathEntries)))
  expect_true(any(grepl("\\.jar$", classPathEntries)))
})


test_that("Modern Tree View config file is generated correctly", {
  modernTreeConfigPath <- .createModernTreeViewConfigFile(
    newickText = "(A:1,B:1);",
    layout = "CIRCULAR",
    leafLabel = FALSE,
    title = "Demo title",
    reverseAxis = TRUE,
    blankSpace = c(1, 2, 3, 4),
    nodeVisualConfigPath = tempfile(fileext = ".tsv")
  )
  modernTreeConfig <- readLines(modernTreeConfigPath, warn = FALSE, encoding = "UTF-8")
  expect_true(any(grepl("^\\$input.nwk.path=", modernTreeConfig)))
  expect_true("$layout.initial=CIRCULAR" %in% modernTreeConfig)
  expect_true("$leaf.show.label=F" %in% modernTreeConfig)
  expect_true("$tree.title.string=Demo title" %in% modernTreeConfig)
  expect_true("$tree.need.reverse.axis=T" %in% modernTreeConfig)
  expect_true("$layout.blank.space=1,2,3,4" %in% modernTreeConfig)
})


test_that("Pathway Family Browser config file is generated correctly", {
  treePath <- tempfile(fileext = ".nwk")
  writeLines("(sp1:1,sp2:1);", treePath, useBytes = TRUE)
  gallery1 <- tempfile(fileext = ".pptx")
  gallery2 <- tempfile(fileext = ".pptx")
  file.create(gallery1)
  file.create(gallery2)
  gallery1 <- normalizePath(gallery1, winslash = "/", mustWork = TRUE)
  gallery2 <- normalizePath(gallery2, winslash = "/", mustWork = TRUE)

  pathwayConfigPath <- .createPathwayFamilyBrowserConfigFile(
    treePath = treePath,
    componentCounts = data.frame(Name = "sp1", WNT3A = 2),
    speciesInfo = data.frame(Name = "sp1", Clade = "A"),
    speciesTraits = data.frame(Name = "sp1", Trait = "Wet"),
    galleryPaths = c(gallery1, gallery2),
    layout = "RECTANGULAR",
    leafLabel = TRUE,
    title = "Pathway browser",
    reverseAxis = FALSE,
    blankSpace = c(10, 20, 30, 40)
  )
  pathwayConfig <- readLines(pathwayConfigPath, warn = FALSE, encoding = "UTF-8")
  expect_true(any(grepl("^\\$pathway.gallery.figure.paths=", pathwayConfig)))
  expect_true(gallery1 %in% pathwayConfig)
  expect_true(gallery2 %in% pathwayConfig)
  expect_true(any(grepl("^\\$pathway.species.info.path=", pathwayConfig)))
  expect_true(any(grepl("^\\$pathway.component.counts.path=", pathwayConfig)))
  expect_true(any(grepl("^\\$species.traits.path=", pathwayConfig)))
  expect_true("$layout.initial=RECTANGULAR" %in% pathwayConfig)
  expect_true("$leaf.show.label=T" %in% pathwayConfig)
  expect_true("$tree.title.string=Pathway browser" %in% pathwayConfig)
  expect_true("$tree.need.reverse.axis=F" %in% pathwayConfig)
  expect_true("$layout.blank.space=10,20,30,40" %in% pathwayConfig)
})
