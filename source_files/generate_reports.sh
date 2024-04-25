#!/bin/bash
set -e

# Purpose: parse an antimicrobial_peptides report, process it, and generate HTML and CSV reports with six columns.

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path/to/filename>"
    exit 1
fi

# Input file provided by the user
input_file="$1"
# Extract filename for the processed file
file_name="${input_file##*/}"
# HMTL report header
report_header="${file_name#report_}"
# Name for CSV file
processed_file="$file_name.csv"
# Name for HTML file
html_report="$file_name.html"

# Process the input CSV file
cat "$input_file" | \
tr -s ' ' ';' | \
awk -F';' '{printf $1; for(i=NF-4; i<=NF; i++) printf ";" $i; print ""}' | \
awk '{ gsub(/,/, ""); print }' | \
awk '{ gsub(/;/, ","); print }' > "$processed_file"

# Generate HTML table rows from the processed input
table_rows=""
while IFS=, read -r file num_seqs sum_len min_len avg_len max_len; do
    table_rows+="<tr>
        <td data-label='File location:&nbsp;'>${file}</td>
        <td data-label='Number of Sequences:&nbsp;'>${num_seqs}</td>
        <td data-label='Sum of Sequence Lengths:&nbsp;'>${sum_len}</td>
        <td data-label='Minimum Length:&nbsp;'>${min_len}</td>
        <td data-label='Average Length:&nbsp;'>${avg_len}</td>
        <td data-label='Maximum Length:&nbsp;'>${max_len}</td>
    </tr>"
done < <(tail -n +2 "$processed_file") # Skip the header line

# Create the HTML report with the table rows
cat <<EOF > "$html_report"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Antimicrobial Peptides Report</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f4f4f4;
        }
        h1, h3 {
            color: #333;
            text-align: center;
        }
        table {
            margin: 20px auto;
            border-collapse: collapse;
            width: 80%;
            background-color: #fff;
        }
        th {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: center; /* Center align text in th and td */
        }
	td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: right; /* Center align text in th and td */
        }
        th {
            background-color: goldenrod;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #ddd;
        }
        /* Add CSS to align the first column to the left */
        td:first-child {
            text-align: left;
        }
         /* Responsive table styles */
        @media screen and (max-width: 600px) {
            table {
                width: 100%;
            }
            thead {
                display: none; /* Hide the table headers on small screens */
            }
            tr {
                margin-bottom: 10px;
                display: block;
                border-bottom: 2px solid #ddd;
            }
            td {
                display: block;
                text-align: right;
                font-size: 13px;
                border-bottom: 1px dotted #ccc;
            }
            td:first-child {
                padding-top: .5em;
            }
            td:last-child {
                padding-bottom: .5em;
            }
            td:before {
                content: attr(data-label);
                float: left;
                font-weight: bold;
            }
        }
    </style>
</head>
<body>
    <h1>Antimicrobial Peptides Report</h1>
    <h3><i>$report_header</i></h3>
    <table>
        <tr>
            <th>File location</th>
            <th>Number of Sequences</th>
            <th>Sum of Sequence Lengths</th>
            <th>Minimum Length</th>
            <th>Average Length</th>
            <th>Maximum Length</th>
        </tr>
        $table_rows
    </table>
</body>
</html>
EOF

# Inform the user that the reports have been generated
# echo "HTML and CSV reports generated."
