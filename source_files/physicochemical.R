library(Peptides)
library(protr)
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(data.table))

args <- commandArgs(trailingOnly = TRUE)
peptides <- readFASTA(args[1])
peptides <- peptides[(sapply(peptides, protcheck))]
aa <- aaComp(seq = peptides)
names(aa) <- names(peptides)
dt <- rbindlist(lapply(aa, as.data.table, keep.rownames = TRUE), idcol = "MatrixName")
colnames(dt) <- c("id", "type", "number", "proportion")

AMPs <- fread(args[2])

calc_dist <- function(data) {
    # Define a custom function to calculate all required statistics
    calc_stats <- function(y) {
    c("2.5th_p" = quantile(y, probs = 0.025), 
    "97.5th_p" = quantile(y, probs = 0.975), 
    "min" = min(y), 
    "max" = max(y),
    "mean" = mean(y))
    }

    # Use aggregate with the custom function to calculate all stats in one call
    stats <- aggregate(proportion ~ type, data = data, FUN = calc_stats)

    # Reshape the data for readability
    stats_df <- do.call(data.frame, stats)

    # Correctly rename the columns to have meaningful names
    # Assuming the result of calc_stats is a matrix with one row per group
    stats_names <- c("type", "2.5th_p", "97.5th_p", "min", "max", "mean")
    names(stats_df) <- stats_names

    return(stats_df)
    }

AMPs_dist <- calc_dist(AMPs)

dt_merge <- merge(dt, AMPs_dist, by = c("type"))
dt_cut <- dt_merge[dt_merge$proportion>=dt_merge$`2.5th_p`&dt_merge$proportion<=dt_merge$`97.5th_p`,]
dt_filtered <- dt_cut %>%
          group_by(id) %>%       # Group by the categorical column
            filter(n() >= 9) %>%                # Filter groups with at least 9 occurrences
                      ungroup()
dt_filtered <- as.data.table(dt_filtered)
unique_ids <- unique(dt_filtered$id)
fwrite(as.data.table(unique_ids), file = args[3], col.names = FALSE)