repoRoot <- normalizePath(file.path(getwd(), ".."), winslash = "/", mustWork = TRUE)
r4eGPSRoot <- file.path(repoRoot, "R4eGPS")
bundleRoot <- normalizePath(file.path(repoRoot, "..", "..", "eGPS_v2.1_windows_x64_selfTest"), winslash = "/", mustWork = TRUE)
bundleDependencyDir <- file.path(bundleRoot, "dependency-egps")

source(file.path(r4eGPSRoot, "R", "zzz.R"))
source(file.path(r4eGPSRoot, "R", "utils.R"))
source(file.path(r4eGPSRoot, "R", "Class_Java_interaction.R"))

configureEGPSSourceRuntime(repoRoot)
stopifnot(checkJarLibAvaliable())

bundleLayout <- .resolveRuntimeLayout(bundleDependencyDir)
stopifnot(identical(bundleLayout$kind, "bundle"))
stopifnot(identical(bundleLayout$root, bundleRoot))
stopifnot(identical(bundleLayout$argsPath, file.path(bundleRoot, "eGPS2.args")))
stopifnot(identical(bundleLayout$bundledJvmPath, file.path(bundleRoot, "jre", "bin", "server", "jvm.dll")))
stopifnot(any(grepl("egps-shell-0.0.1.jar$", bundleLayout$classPathEntries)))

local({
  originalStoragePath <- storage_file_path
  originalPromptForRuntimeRoot <- .promptForRuntimeRoot
  originalDiscoverRepoRoot <- .discoverRepoRoot
  testStoragePath <- tempfile(fileext = ".rds")

  tryCatch(
    {
      storage_file_path <<- testStoragePath
      .promptForRuntimeRoot <<- function() bundleDependencyDir
      .discoverRepoRoot <<- function() NA_character_

      promptedLayout <- .resolveRuntimeLayout(quiet = FALSE)
      promptedVars <- getGlobalVars()

      stopifnot(identical(promptedLayout$kind, "bundle"))
      stopifnot(identical(promptedLayout$root, bundleRoot))
      stopifnot(identical(promptedVars[[egps_repo_root_key]], bundleRoot))
      stopifnot(identical(promptedVars[[java_path_key]], file.path(bundleRoot, "jre", "bin", "server", "jvm.dll")))
    },
    finally = {
      storage_file_path <<- originalStoragePath
      .promptForRuntimeRoot <<- originalPromptForRuntimeRoot
      .discoverRepoRoot <<- originalDiscoverRepoRoot
      if (file.exists(testStoragePath)) {
        file.remove(testStoragePath)
      }
    }
  )
})

javaArgs <- .parseEGPSArgs(repoRoot)
stopifnot("--add-opens=java.desktop/java.awt=ALL-UNNAMED" %in% javaArgs)
stopifnot("-Dcom.sun.xml.bind.v2.bytecode.ClassTailor.noOptimize" %in% javaArgs)

classPathEntries <- .getRuntimeClassPathEntries(repoRoot)
stopifnot(any(grepl("egps-main\\.gui/out/production/egps-main\\.gui$", classPathEntries)))
stopifnot(any(grepl("egps-pathway\\.evol\\.browser/out/production/egps-pathway\\.evol\\.browser$", classPathEntries)))
stopifnot(any(grepl("\\.jar$", classPathEntries)))

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
stopifnot(any(grepl("^\\$input.nwk.path=", modernTreeConfig)))
stopifnot("$layout.initial=CIRCULAR" %in% modernTreeConfig)
stopifnot("$leaf.show.label=F" %in% modernTreeConfig)
stopifnot("$tree.title.string=Demo title" %in% modernTreeConfig)
stopifnot("$tree.need.reverse.axis=T" %in% modernTreeConfig)
stopifnot("$layout.blank.space=1,2,3,4" %in% modernTreeConfig)

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
stopifnot(any(grepl("^\\$pathway.gallery.figure.paths=", pathwayConfig)))
stopifnot(gallery1 %in% pathwayConfig)
stopifnot(gallery2 %in% pathwayConfig)
stopifnot(any(grepl("^\\$pathway.species.info.path=", pathwayConfig)))
stopifnot(any(grepl("^\\$pathway.component.counts.path=", pathwayConfig)))
stopifnot(any(grepl("^\\$species.traits.path=", pathwayConfig)))
stopifnot("$layout.initial=RECTANGULAR" %in% pathwayConfig)
stopifnot("$leaf.show.label=T" %in% pathwayConfig)
stopifnot("$tree.title.string=Pathway browser" %in% pathwayConfig)
stopifnot("$tree.need.reverse.axis=F" %in% pathwayConfig)
stopifnot("$layout.blank.space=10,20,30,40" %in% pathwayConfig)

cat("R runtime helper tests passed\n")
