import argparse
import pandas as pd
from collections import Counter
import re
import sys

# Set up argument parser
parser = argparse.ArgumentParser(description='Process a multiple sequence alignment (MSA) and output nucleotide/protein counts in nominal or compositional format. Also outputs a regex motif to standard out.')
parser.add_argument('input_file', type=str, help='Path to the input FASTA file')
parser.add_argument('--coda', action='store_true', help='Output compositional data with max 2 decimal places')
parser.add_argument('--horizontal', action='store_true', help='Carry out the compositional count row-wise')
parser.add_argument('--vertical', action='store_true', help='Carry out the compositional count column-wise')
parser.add_argument('--regex', action='store_true', help='Generate a regex pattern')
args = parser.parse_args()

# Function to set flags for full analysis
def set_full_analysis_flags():
    args.coda = True
    args.horizontal = True

# If the --full-analysis flag is used, set the other flags
if args.regex:
    set_full_analysis_flags()

# Function to read and check FASTA sequences
def read_fasta(file_path):
    with open(file_path, 'r') as file:
        sequence = ''
        for line in file:
            if line.startswith('>'):
                if sequence:
                    yield sequence
                    sequence = ''
            else:
                sequence += line.strip()
        if sequence:
            yield sequence

# Function to generate regex pattern
def generate_regex_pattern(df):
    # Initialize an empty list to store the regex pattern for each position
    regex_patterns = []

    # Iterate over each row in the DataFrame
    for index, row in df.iterrows():
        # Exclude the '-' character from consideration
        row = row[(row.index != 'Position') & (row.index != '-')]
        
        # Sort the amino acids by frequency in descending order
        sorted_row = row.sort_values(ascending=False)
        
        # Calculate the cumulative sum of the top n amino acids
        cumulative_sum_top_n = sorted_row.iloc[:2ls
        ].sum() # CUMULATIVE SUM OF TOP TWO!

        # Calculate the number of non-zero elements
        non_zero_count = (sorted_row != 0).sum()

        # Calculate the total number of elements
        total_count = len(sorted_row)
        
        # If the cumulative sum of the top n amino acids exceeds n% and at least 50% of the elements in a row have non-zero values, include them in the pattern
        if cumulative_sum_top_n > 70 and non_zero_count >= 0.5 * total_count:
            # Create a boolean mask where each True corresponds to an amino acid contributing more than 10%
            mask = sorted_row > 10
            # Take n amino acids that contribute to this sum
            #contributing_aas = sorted_row.iloc[:1].index # Take only the most abundant amino acid
            contributing_aas = sorted_row[mask].index
            pattern = f"[{''.join(contributing_aas)}]"
        else:
            # If the condition is not met, use '.' to match any character
            pattern = '.'
        
        # Append the pattern for the current position to the list
        regex_patterns.append(pattern)
    
    # Join all position patterns to form the final regex pattern
    initial_pattern = ''.join(regex_patterns)

    # Replace multiple '.' with '.*' to match any number of any characters
    final_pattern = re.sub(r'\.{2,}', '..*', initial_pattern)
    #final_pattern = initial_pattern

    return final_pattern

# Read sequences and ensure they are of equal length
sequences = list(read_fasta(args.input_file))
sequence_length = len(sequences[0])
if not all(len(seq) == sequence_length for seq in sequences):
    raise ValueError("Not all FASTA sequences are of equal length.")

# Process sequences
nucleotide_counts = {i: Counter() for i in range(1, sequence_length + 1)}

for seq in sequences:
    for pos, nucleotide in enumerate(seq, start=1):
        nucleotide_counts[pos][nucleotide] += 1

# Convert the counts to a DataFrame
df = pd.DataFrame([
    {'Position': pos, 'AminoAcid': nuc, 'Count': count}
    for pos, counters in nucleotide_counts.items()
    for nuc, count in counters.items()
])

# Pivot the table
pivoted_df = df.pivot(index='Position', columns='AminoAcid', values='Count')

# Fill NaN values with 0 if any, since a missing value implies a count of 0
pivoted_df = pivoted_df.fillna(0).astype(int)

# Drop "-" count
pivoted_df = pivoted_df.drop(columns=['-'])

# If --coda flag is used, convert counts to compositional data
if args.coda:
    if not args.horizontal and not args.vertical:
        print("Should compositional analysis be --vertical or --horizontal?")
        sys.exit(1) 
    elif args.horizontal and args.vertical:
        print("Cannot use --vertical and --horizontal simultanously. Note: --regex uses --horizontal implicitly.")
        sys.exit(1) 
    elif args.horizontal:
        pivoted_df = pivoted_df.div(pivoted_df.sum(axis=1), axis=0) * 100
    elif args.vertical:
        pivoted_df = pivoted_df.div(pivoted_df.sum(axis=0), axis=1) * 100
    pivoted_df = pivoted_df.round(2)

# Reset the index to get 'Position' back as a column
pivoted_df.reset_index(inplace=True)

if args.horizontal:
    if args.regex:
        regex_term = generate_regex_pattern(pivoted_df)
        print("Regex term is: " + regex_term) 

# Save the pivoted DataFrame to a new CSV file
if args.horizontal:
    pivoted_df.to_csv('table_output_horizontal_coda.csv', index=False)
    print("Table saved as table_output_horizontal_coda.csv")
if args.vertical:
    pivoted_df.to_csv('table_output_vertical_coda.csv', index=False)
    print("Table saved as table_output_vertical_coda.csv")
if not args.horizontal and not args.vertical:
    pivoted_df.to_csv('table_output_standard.csv', index=False)
    print("Table saved as table_output_standard.csv")