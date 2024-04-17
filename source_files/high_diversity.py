import sys
from Bio import SeqIO

# Check for proper usage
if len(sys.argv) != 3:
    print("Usage: python script.py input.fasta output.fasta")
    sys.exit(1)

# Define the twenty standard amino acids
amino_acids = set('ACDEFGHIKLMNPQRSTVWY')

def contains_all_amino_acids(sequence):
    return amino_acids.issubset(set(sequence))

# Get the file names from the command line
input_file = sys.argv[1]
output_file = sys.argv[2]

with open(output_file, 'w') as output_handle:
    for record in SeqIO.parse(input_file, 'fasta'):
        sequence = str(record.seq).upper()
        if contains_all_amino_acids(sequence):
            SeqIO.write(record, output_handle, 'fasta')