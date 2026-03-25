# Demo: Launch eGPS desktop from R
#
# This example demonstrates the basic usage of R4eGPS:
# 1. Configure the eGPS runtime pointing to the installed bundle
# 2. Launch the eGPS desktop
# 3. Extract tree node names via the Java bridge

library(R4eGPS)

configureEGPSSourceRuntime(
  repoRoot = "C:/Users/yudal/Documents/project/eGPS2/eGPS_v2.1_windows_x64_selfTest/dependency-egps"
)

egps <- launchEGPSDesktop()

nodeNames <- evoltre_getNodeNames(
  treePath = "C:/Users/yudal/.egps2/config/bioData/example/9_model_species_evolution.nwk",
  getOTU = TRUE,
  getHTU = TRUE
)

print(nodeNames)
Sys.sleep(10)
