####################3
setwd("~/Documents/malaria")
library(rcdk)
library(data.table)


target_data <- fread("ChEMBL_21_MWTlt900_standardized.csv")
query_data <- read.csv("GAMO_PFdata_200115.csv", stringsAsFactors = FALSE)
query_smiles <- query_data$smiles[1:13403]
target_smiles <- target_data$smiles[1030001:1048574]

#sample <- fread("results_10000.csv")


#df <- data.frame(sample)
#smiles <- df$smiles
#rownames(df) <- smiles
#first <- df[2]
#hists <- which(first > 0.1)

#duplicated <- smiles[duplicated(smiles)]

##calculating all 
options(java.parameters = "-Xmx31000m")
target.mols <- parse.smiles(query_smiles)
#library(parallel)
#cl <- makeCluster(24)
#clusterExport(cl = cl, varlist = "target.mols")
#target.fps <- parLapply(cl = cl,
#                        target.mols,
#                        get.fingerprint, type = "circular")
target.fps <- lapply(target.mols, get.fingerprint, type = "circular")

saveRDS(target.fps, "target_fps_1048574.Rds")



query_mols <- parse.smiles(query_smiles)[[1]]
target.mols <- parse.smiles(target_smiles)

query.fp <- get.fingerprint(query_mols, type = "circular", depth = 3)
library(rbenchmark)
benchmark(
target.fps_1 <- lapply(target.mols, get.fingerprint, 
                       type = "circular", depth = 3, size = 1024),
target.fps_2 <- lapply(target.mols, get.fingerprint,
                       type = "circular", depth = 6, size = 1024),
order = "elapsed", replications = 1)



#tanimoto_similarity <- unlist(lapply(target.fps, distance, fp2 = query.fp,
#                                     method = 'tanimoto'))
#results <- as.data.frame(tanimoto_similarity)


#my_results <- data.frame()
setwd("~/Documents/malaria")
target_data <- readRDS("target_fps_390000.Rds")
query_data <- readRDS("query_fp_GAMPO.Rds")

library(parallel)
library(doSNOW)
cl <- makeCluster(23)
#clusterExport(cl, "target.fps")
registerDoSNOW(cl)
my_results <- list(1:13403)
my_results <- foreach(i = 1:13403, .packages = 'rcdk') %dopar% {
  #query.mol <- parse.smiles(query_smiles)[[i]]
  #target.mols <- parse.smiles(target_smiles)
  #query.fp <- get.fingerprint(query.mol, type = "circular")
  query.fp <- query_data[[i]]
  #target.fps <- lapply(target.mols, get.fingerprint, type = "circular")
  #target.fps <- readRDS("target_fps_10000.Rds")
  target.fps <- target_data
  tanimoto_similarity <- unlist(lapply(target.fps, distance,
                                       fp2 = query.fp,
                                       method = "tanimoto"))
  rm(query.mol)
  rm(target.mols)
  rm(query.fp)
  rm(target.fps)
  my_results[[i]] <- tanimoto_similarity
                      }

my_results_df <- as.data.frame(do.call("rbind", my_results))

write.csv(my_results_df, file = "results_390000.csv", 
          row.names = FALSE)
