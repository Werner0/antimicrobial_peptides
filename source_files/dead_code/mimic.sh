#!/bin/bash

#Purpose: Mimics a fasta file in header count and sequence lengths, but replaces the sequences with random nucleotides.

# Check for input argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <fasta_file>"
    exit 1
fi

# Input FASTA file
FASTA_FILE=$1

# Check if the input FASTA file exists
if [ ! -f "$FASTA_FILE" ]; then
    echo "File $FASTA_FILE does not exist."
    exit 1
fi

# Extract the base name of the input file
BASE_NAME=$(basename "$FASTA_FILE")

# Create a synthetic FASTA file name
SYNTHETIC_FASTA="synthetic_$BASE_NAME"

# Process the FASTA file
awk '/^>/{ 
    if(seq!=""){ print seq }
    seq="";
    print ">seq_" counter++; 
    next; 
}
{
    seq=seq""$0;
}
END{
    if(seq!=""){ print seq }
}' $FASTA_FILE | \
awk 'BEGIN{FS=" "}/^>/{print;next;}{
    sequence=$0;
    len=length(sequence);
    srand();
    synthetic_sequence="";
    for(i=1;i<=len;i++){
        r=int(rand()*4);
        nucleotide=(r==0?"A":(r==1?"C":(r==2?"G":"T")));
        synthetic_sequence=synthetic_sequence nucleotide;
    }
    print synthetic_sequence;
}' > $SYNTHETIC_FASTA

echo "Synthetic FASTA file created: $SYNTHETIC_FASTA"