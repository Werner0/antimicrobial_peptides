#!/bin/bash

# Calculate the total number of sequences in the FASTA file
total=$(grep -c '^>' APD_sequence_release_09142020.fasta)

# Loop through all combinations of amino acids to create tripeptides
for aa1 in A C D E F G H I K L M N P Q R S T V W Y; do
    for aa2 in A C D E F G H I K L M N P Q R S T V W Y; do
        for aa3 in A C D E F G H I K L M N P Q R S T V W Y; do
            tripeptide="$aa1$aa2$aa3"
            echo -n "$tripeptide: "
            # Count occurrences of each tripeptide and calculate frequency
            count=$(seqkit seq -s APD_sequence_release_09142020.fasta | grep -o "$tripeptide" | wc -l)
            echo "scale=6; $count / $total" | bc
        done
    done
done > APD_tripeptide.txt