library(protr)
library(data.table)

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Initialize variables for command line arguments
fasta_file <- NULL
label <- "NA"
output_path <- NULL

# Manually parse the command line arguments
for (i in seq(1, length(args), 2)) {
  if (args[i] == '-f' || args[i] == '--file') {
    fasta_file <- args[i + 1]
  } else if (args[i] == '-l' || args[i] == '--label') {
    label <- args[i + 1]
  } else if (args[i] == '-o' || args[i] == '--output') {
    output_path <- args[i + 1]
  }
}

# Check if the file argument is provided
if (is.null(fasta_file)) {
  stop("No FASTA file provided. Use --file to specify the FASTA file.", call. = FALSE)
}

# Check if the output path argument is provided
if (is.null(output_path)) {
  stop("No output path provided. Use --output to specify the output path and filename.", call. = FALSE)
}

# Read the FASTA file and filter valid protein sequences
x <- readFASTA(fasta_file)
#x <- x[sapply(x, protcheck)]

# Initialize an empty data.table
dt_moreau <- data.table()

# Loop over each protein sequence and calculate Moreau-Broto autocorrelation descriptors
for (i in seq_along(x)) {
  sequence <- x[[i]]
  header <- names(x)[i]  # Extract the header for the current sequence
  moreau_broto <- extractMoreauBroto(sequence, nlag = 3)
  dt_temp_moreau <- data.table(header = header, t(moreau_broto), length = nchar(sequence))
  dt_moreau <- rbind(dt_moreau, dt_temp_moreau, fill = TRUE)
}

# Write the data.table to the specified output path
fwrite(dt_moreau, file = output_path)