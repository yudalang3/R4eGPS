# Runtime helper tests migrated to testthat format.
# These tests verify runtime layout resolution, config file persistence,
# JVM argument parsing, and VOICE configuration generation.

.namespaceEnv <- asNamespace("R4eGPS")


.assignNamespaceValue <- function(name, value) {
  unlockBinding(name, .namespaceEnv)
  assign(name, value, .namespaceEnv)
  lockBinding(name, .namespaceEnv)
}


.findBundleRuntimeForTests <- function() {
  envCandidate <- Sys.getenv("EGPS_BUNDLE_ROOT", "")
  candidates <- character()
  if (nzchar(envCandidate)) {
    candidates <- c(candidates, envCandidate)
  }

  current <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  repeat {
    candidates <- c(
      candidates,
      file.path(current, "eGPS_v2.1_windows_x64_selfTest"),
      file.path(current, "dependency-egps")
    )
    parent <- dirname(current)
    if (identical(parent, current)) {
      break
    }
    current <- parent
  }

  for (candidate in unique(candidates)) {
    layout <- tryCatch(
      R4eGPS:::.resolveRuntimeLayout(candidate, quiet = TRUE),
      error = function(...) NULL
    )
    if (!is.null(layout) && identical(layout$kind, "bundle")) {
      return(layout)
    }
  }

  NULL
}


.bundleRuntime <- .findBundleRuntimeForTests()


.skipIfBundleUnavailable <- function() {
  if (is.null(.bundleRuntime)) {
    testthat::skip("Bundle runtime not available for wrapper integration tests.")
  }
}


test_that("configureEGPSSourceRuntime works and checkJarLibAvailable returns TRUE", {
  .skipIfBundleUnavailable()
  configureEGPSSourceRuntime(file.path(.bundleRuntime$root, "dependency-egps"))
  expect_true(R4eGPS:::checkJarLibAvailable())
})


test_that("bundle layout is resolved from dependency-egps directory", {
  .skipIfBundleUnavailable()
  bundleDependencyDir <- file.path(.bundleRuntime$root, "dependency-egps")
  bundleLayout <- R4eGPS:::.resolveRuntimeLayout(bundleDependencyDir)
  expect_identical(bundleLayout$kind, "bundle")
  expect_identical(bundleLayout$root, .bundleRuntime$root)
  expect_identical(bundleLayout$argsPath, file.path(.bundleRuntime$root, "eGPS2.args"))
  expect_identical(
    bundleLayout$bundledJvmPath,
    file.path(.bundleRuntime$root, "jre", "bin", "server", "jvm.dll")
  )
  expect_true(any(grepl("egps-shell-0.0.1.jar$", bundleLayout$classPathEntries)))
})


test_that("interactive prompt resolves to bundle and persists vars", {
  .skipIfBundleUnavailable()
  originalStoragePath <- get("storage_file_path", .namespaceEnv)
  originalPromptForRuntimeRoot <- R4eGPS:::.promptForRuntimeRoot
  originalDiscoverRepoRoot <- R4eGPS:::.discoverRepoRoot
  testStoragePath <- tempfile(fileext = ".rds")
  bundleDependencyDir <- file.path(.bundleRuntime$root, "dependency-egps")

  on.exit({
    .assignNamespaceValue("storage_file_path", originalStoragePath)
    .assignNamespaceValue(".promptForRuntimeRoot", originalPromptForRuntimeRoot)
    .assignNamespaceValue(".discoverRepoRoot", originalDiscoverRepoRoot)
    if (file.exists(testStoragePath)) file.remove(testStoragePath)
  })

  .assignNamespaceValue("storage_file_path", testStoragePath)
  .assignNamespaceValue(".promptForRuntimeRoot", function() bundleDependencyDir)
  .assignNamespaceValue(".discoverRepoRoot", function() NA_character_)

  promptedLayout <- R4eGPS:::.resolveRuntimeLayout(quiet = FALSE)
  promptedVars <- getGlobalVars()

  expect_identical(promptedLayout$kind, "bundle")
  expect_identical(promptedLayout$root, .bundleRuntime$root)
  expect_identical(promptedVars[[R4eGPS:::egps_repo_root_key]], .bundleRuntime$root)
  expect_identical(
    promptedVars[[R4eGPS:::java_path_key]],
    file.path(.bundleRuntime$root, "jre", "bin", "server", "jvm.dll")
  )
})


test_that("JVM arguments are parsed correctly from eGPS.args", {
  .skipIfBundleUnavailable()
  javaArgs <- R4eGPS:::.parseEGPSArgs(.bundleRuntime$root)
  expect_true("--add-opens=java.desktop/java.awt=ALL-UNNAMED" %in% javaArgs)
  expect_true("-Dcom.sun.xml.bind.v2.bytecode.ClassTailor.noOptimize" %in% javaArgs)
})


test_that("classpath entries contain expected paths", {
  .skipIfBundleUnavailable()
  classPathEntries <- R4eGPS:::.getRuntimeClassPathEntries(.bundleRuntime$root)
  expect_true(any(grepl("egps-shell-0\\.0\\.1\\.jar$", classPathEntries)))
  expect_true(any(grepl("\\.jar$", classPathEntries)))
})


test_that("Modern Tree View config file is generated correctly", {
  modernTreeConfigPath <- R4eGPS:::.createModernTreeViewConfigFile(
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

  pathwayConfigPath <- R4eGPS:::.createPathwayFamilyBrowserConfigFile(
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


test_that("evoltre_getNodeNames accepts the legacy tree_path argument name", {
  .skipIfBundleUnavailable()
  configureEGPSSourceRuntime(file.path(.bundleRuntime$root, "dependency-egps"))

  treePath <- tempfile(fileext = ".nwk")
  writeLines("(A:1,B:1);", treePath, useBytes = TRUE)

  nodeNames <- evoltre_getNodeNames(tree_path = treePath, getOTU = TRUE, getHTU = FALSE)
  expect_identical(nodeNames, c("A", "B"))
})
