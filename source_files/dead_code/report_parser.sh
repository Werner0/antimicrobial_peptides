#!/bin/bash

# Purpose: parse an antimicrobial_peptides report.

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Input file provided by the user
input_file="$1"

# Output file with 'parsed_' prefix
output_file="${input_file%.csv}.csv"

# Process the input file and save the output to the output file
cat "$input_file" | \
tr -s ' ' ';' | \
awk -F';' '{printf $1; for(i=NF-4; i<=NF; i++) printf ";" $i; print ""}' | \
awk '{ gsub(/,/, ""); print }' | \
awk '{ gsub(/;/, ","); print }' > "$output_file"

# Inform the user of the output file location
echo "Output written to $output_file"
