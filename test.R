library(R4eGPS)
egps <- R4eGPS::launchEGPS_withinR("C:/Users/yudal/Documents/project/eGPS2/eGPSv2_forMyselfUsage")

compsLength <- 10
sampleSize <- 8
gNames <- paste0('Gene', 1:compsLength)
simulatedData <- setNames(
  as.data.frame(replicate(sampleSize, runif(compsLength, 0, sampleSize))),
  paste0('S', 1:sampleSize)
)
df <- data.frame(name = gNames, simulatedData,
                      cat1 = rep(c("Cat1","Cat2","Cat3"), each = 3, length.out = compsLength),
                      cat2 = rep(c("Cat1","Cat2","Cat3"), each = 4, length.out = compsLength),
                      value = 1)
# make sure the column names are matched
correlationVis_expressionProfile(egps, df,expMatrixCol = c("name"),
                                 cat1Col = c("name", "cat1"),
                                 cat2Col = c("name", "cat2", "value"))


##########################


fastaPath <- "fastaPath"
entries <- letters
outPath <- "outPath"
keepSearch <-  F


R4eGPS::fastadumper_partialMatch(fastaPath,entries,outPath,keepSearch)
##########################
nwk_tree_path <- "C:/Users/yudal/.egps2/config/bioData/example/9_model_species_evolution.nwk"
R4eGPS::evoltre_getNodeNames(tree_path = nwk_tree_path, onlyLeaf = T)















##########################
list1 <- list(
  gene1 = list(
    length = 250,
    start = c(1, 10, 101, 200),
    end = c(8, 56, 152, 230),
    color = c("#E63946", "#457B9D", "#2A9D8F", "#F4A261")
  ),
  gene2 = list(
    length = 350,
    start = c(1, 180, 210, 261),
    end = c(150, 200, 250, 300),
    color = c("#E63946", "#457B9D", "#2A9D8F", "#F4A261")
  ),
  gene3 = list(
    length = 300,
    start = c(51, 101, 200),
    end = c(100, 150, 231),
    color = c("#2A9D8F", "#F4A261", "#1D3557")
  )
)
R4eGPS::structDraw_multi_genes(list1)










list2 <- list(
  gene1 = list(
    length = 100,
    start = 1,
    end = 50,
    color = c("#E63946")
  ),
  gene3 = list(
    length = 300,
    start = c(51, 101),
    end = c(100, 150),
    color = c("#2A9D8F", "#F4A261")
  )
)



