library(Peptides)
library(protr)
library(dplyr)
library(data.table)

peptides <- readFASTA("APD_sequence_release_09142020.fasta")
peptides <- peptides[(sapply(peptides, protcheck))]
aa <- aaComp(seq = peptides)
names(aa) <- names(peptides)
dt <- rbindlist(lapply(aa, as.data.table, keep.rownames = TRUE), idcol = "MatrixName")
colnames(dt) <- c("id", "type", "number", "proportion")
fwrite(dt, file = "APD_sequence_release_09142020.properties")
