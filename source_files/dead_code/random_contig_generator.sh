#!/bin/bash

# Purpose: generate a random nucleotide contig of n nucleotides.

#!/bin/bash

# Check if the user has provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number_of_nucleotides>"
    exit 1
fi

# The number of nucleotides to generate
num_nucleotides=$1
# The filename and header
filename="random_contig_${num_nucleotides}.fasta"

# Generate the random nucleotide sequence and write to the file
awk -v n="$num_nucleotides" 'BEGIN {
    srand();  # Seed the random number generator
    nucleotides = "ACGT";
    seq = "";
    for (i = 0; i < n; i++) {
        seq = seq""substr(nucleotides, int(rand() * length(nucleotides)) + 1, 1);
    }
    print ">random_contig_" n "\n" seq;
}' > "$filename"

echo "FASTA file generated: $filename"