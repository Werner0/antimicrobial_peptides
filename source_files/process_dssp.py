import glob
import pandas as pd
import sys

# Check if the required arguments were provided
if len(sys.argv) < 3:
    print("Usage: python script.py <path_to_dssp_files> <output_csv_path>")
    sys.exit(1)

input_path = sys.argv[1]  # Get the input path from the command line
output_csv_path = sys.argv[2]  # Get the output path from the command line

# Define the structure types
structure_types = ['H', 'B', 'E', 'G', 'I', 'T', 'S', '-']

# Initialize a list to hold the counts for each file
all_counts = []

# Get a list of all .dssp files in the specified directory
dssp_files = glob.glob(f'{input_path}/*.dssp')

# Process each file
for dssp_file in dssp_files:
    # Initialize a dictionary to hold the counts of each structure type
    structure_counts = {structure_type: 0 for structure_type in structure_types}

    with open(dssp_file, 'r') as file:
        # Skip header lines until we reach the start of the residue data
        for line in file:
            if line.startswith('  #  RESIDUE AA STRUCTURE'):
                break  # The data starts after this line

        # Process each line after the header
        for line in file:
            # Extract the structure character, which is typically in a fixed position
            structure_char = line[16]  # This index may need to be adjusted

            # Increment the count for the observed structure type
            if structure_char in structure_counts:
                structure_counts[structure_char] += 1
            else:
                # Handle any special cases or unknown structure types
                structure_counts['-'] += 1  # Assuming '-' is used for unknown types

    # Add the file name and its counts to the list
    structure_counts['File'] = dssp_file
    all_counts.append(structure_counts)

# Create a DataFrame from the list of counts
df = pd.DataFrame(all_counts)

# Set the file name as the index of the DataFrame
df.set_index('File', inplace=True)

# Sort the columns to maintain the order of structure types
df = df[structure_types]

# Output the matrix
#print(df)

# Save the matrix to the specified CSV file
df.to_csv(output_csv_path)
