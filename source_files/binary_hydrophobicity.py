import argparse
from Bio import SeqIO

# Define hydrophobic and polar residues
hydrophobic_residues = "AILMFWV"
polar_residues = "STCNQY"

# Function to convert sequence to binary pattern
def sequence_to_binary(seq):
    binary_seq = ""
    for residue in seq:
        if residue in hydrophobic_residues:
            binary_seq += "H"
        elif residue in polar_residues:
            binary_seq += "P"
        else:
            binary_seq += "X"  # For residues that are neither clearly hydrophobic nor polar
    return binary_seq

# Set up argument parser
parser = argparse.ArgumentParser(description='Convert protein sequences to binary patterns.')
parser.add_argument('input_file', type=str, help='Path to the input FASTA file.')
parser.add_argument('output_file', type=str, help='Path to the output file where binary patterns will be written.')

# Parse arguments
args = parser.parse_args()

# Read the FASTA file and write the output to a new file
with open(args.output_file, "w") as outfile:
    for record in SeqIO.parse(args.input_file, "fasta"):
        sequence = str(record.seq)
        binary_sequence = sequence_to_binary(sequence)
        outfile.write(f">{record.id}\n{binary_sequence}\n")

#print(f"Binary patterns have been written to {args.output_file}")
