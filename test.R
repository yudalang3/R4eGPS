library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/Users/yudal/Documents/project/eGPS2/eGPS_v2.1_windows_x64_selfTest/dependency-egps"
)

egps <- launchEGPSDesktop()

nodeNames <- evoltre_getNodeNames(
  tree_path = "C:/Users/yudal/.egps2/config/bioData/example/9_model_species_evolution.nwk",
  getOTU = TRUE,
  getHTU = TRUE
)

print(nodeNames)
Sys.sleep(10)
