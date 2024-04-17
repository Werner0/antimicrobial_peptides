library(data.table)
library(strex)
dt <- fread("APD_PDBs_dssp.csv")
dt2 <- fread("160k_PDBs_dssp.csv")
sequences <- fread("sequences.txt", header = FALSE)
dt2$id <- str_before_first(dt2$File, "\\.")
dt2 <- dt2[dt2$id %in% sequences$V1,]

percentiles <- apply(dt[,c(2:9)], 2, function(x) quantile(x, probs = c(0.25, 0.75), na.rm = TRUE))
percentiles <- data.table(percentiles)

x <- dt2[dt2$H<=percentiles$H[2]&
      dt2$B<=percentiles$B[2]&
      dt2$E<=percentiles$E[2]&
      dt2$G<=percentiles$G[2]&
      dt2$I<=percentiles$I[2]&
      dt2$T<=percentiles$T[2]&
      dt2$S<=percentiles$S[2]&
      dt2$`-`>=percentiles$`-`[1]&
      dt2$`-`<=percentiles$`-`[2],]
