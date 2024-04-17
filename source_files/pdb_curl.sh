#!/bin/bash

source parameters.conf

# Check if an input file was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <multi-fasta-file>"
    exit 1
fi

# Input multi-FASTA file
fasta_file="$1"

# Temporary file to hold individual FASTA sequences
temp_fasta="temp.fasta"

# Variable to hold the current header
current_header=""

# Function to post sequence to API with retry logic
post_sequence() {
    local sequence="$1"
    local retries=3
    local count=0
    local response

    while [ $count -lt $retries ]; do
        response=$(curl -X POST --insecure --data "$sequence" https://api.esmatlas.com/foldSequence/v1/pdb/)
        local status=$?
        if [ $status -eq 0 ]; then
            echo "$response"
            return 0
        else
            let count++
            echo "Attempt $count of $retries failed. Retrying in 5 seconds..."
            sleep 5
        fi
    done

    echo "Failed to post sequence after $retries attempts."
    return 1
}

# Read the multi-FASTA file line by line
while read -r line; do
    # Check for the header line
    if [[ "$line" == ">"* ]]; then
        # If we have a current header, it means we've reached a new sequence
        if [ ! -z "$current_header" ]; then
            # Post the sequence to the API and save the response
            sequence=$(cat "$temp_fasta" | tr -d '\n')
            response=$(post_sequence "$sequence")
            if [ $? -eq 0 ]; then
                # Save the response to a file named after the header with a .pdb suffix
                echo "$response" > "${results_directory}/pdbs/${current_header}.pdb"
            else
                #Write an empty file
                echo "" > "${results_directory}/pdbs/${current_header}.pdb.fail"
            fi
        fi
        # Set the current header to the line without the leading '>'
        current_header=$(echo "$line" | sed 's/>//')
        # Empty the temp_fasta for the next sequence
        > "$temp_fasta"
    else
        # Append sequence lines to the temp_fasta
        echo "$line" >> "$temp_fasta"
    fi
done < "$fasta_file"

# Don't forget to process the last sequence in the file
if [ ! -z "$current_header" ]; then
    sequence=$(cat "$temp_fasta" | tr -d '\n')
    response=$(post_sequence "$sequence")
    if [ $? -eq 0 ]; then
        echo "$response" > "${results_directory}/pdbs/${current_header}.pdb"
    else
        #Write an empty file
        echo "" > "${results_directory}/pdbs/${current_header}.pdb.fail"
    fi
fi

# Clean up the temporary file
rm "$temp_fasta"
