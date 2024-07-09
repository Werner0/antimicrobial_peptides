#!/bin/bash
set -e
#set -x
start_time=$(date +%s)

# Load parameters from configuration file
if [ ! -f parameters.conf ]; then
  # File not found, echo a message
  echo "Navigate to the project root directory and run end_to_end.sh from there."
  exit 1
fi
source parameters.conf

# Function to check if required tools are available
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        if [ "$1" = "pfilt" ]; then
            echo "Configuring pfilt."
	    cd setup
	    bash configure.sh
	    cd ..
        else
            echo "Error: $1 could not be found. Please install $1 to continue or activate the candidates conda environment."
	    exit 1
	fi
    fi
}

# Check for required tools
check_tool getorf
check_tool transeq
check_tool seqkit
check_tool Rscript
check_tool python
check_tool pfilt
check_tool fasta_doctor_x86_64

# Check if a genome file is provided as an input
if [ -z "$1" ]; then
    echo "[INFO] No nucleotide sequences provided. Using example nucleotides from $genome"
else
    genome="$1"
    # Check if the file exists and is readable
    if [ ! -f "$genome" ] || [ ! -r "$genome" ]; then
        echo "[ERROR] File doesn't exist or read permissions are required."
        exit 1
    fi
    # Check if the file has a .fasta or .fna extension
    if [[ ! "$genome" =~ \.(fasta|fna)$ ]]; then
        echo "[ERROR] Only .fasta and .fna files are acceptable as input."
        exit 1
    fi
    # Check if the file conforms to the FASTA format
    if ! grep -q "^>" "$genome"; then
        echo "[ERROR] $genome does not have headers starting with '>'."
        exit 1
    fi
    # Check for valid nucleotide sequences (including wildcards)
    if grep -v "^>" "$genome" | grep -qiE "[^ACGTURYKMSWBDHVN]"; then
        echo "[ERROR] $genome contains invalid nucleotide sequences."
        exit 1
    fi
    # Check that there is at least one sequence line following a header line
    if ! awk 'BEGIN{IGNORECASE=1} /^>/ {header=1; next} /^[ACGTURYKMSWBDHVN]+$/ {if(header) {seq=1; header=0}} END {exit !(seq)}' "$genome"; then
        echo "[ERROR] $genome does not contain any sequences following the headers."
        exit 1
    fi
    echo "[INFO] File $genome passed basic FASTA format checks."
fi

# Check if the directory already exists
if [ -d "$results_directory" ]; then
    # Warn if directory exists
    echo "[WARN] Output directory already exists. Previous results will be overwritten."
    read -p "Do you want to continue? (Y/N) " -n 1 -r
    echo #Newline

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # User chose to continue
        echo "[INFO] Overwriting previous results."
	find "$results_directory" -type f -exec rm {} \;
	rm -f log.txt
	mkdir -p "$results_directory/pdbs"
    else
        # User chose not to continue
        exit 1
    fi
else
    # Directory does not exist
    mkdir -p "$results_directory/pdbs"
fi

# Function to log messages with timestamps
log_message() {
    echo "[PIPELINE $(date)] $1" | tee -a log.txt
}

# Function to append batch names to fasta headers
modify_fasta_headers() {
    local string_to_append="$1"
    shift
    for fasta_file in "$@"; do
        # Create a temporary file
        tmp_file=$(mktemp)

        # Use awk to append the string to the header and write to the temporary file
        awk -v append_str="$string_to_append" '/^>/{print $0 append_str; next} {print}' "$fasta_file" > "$tmp_file"

        # Move the temporary file to the original file
        mv "$tmp_file" "$fasta_file"
    done
}

check_files_exist() {
    local all_files_exist=true
    local missing_files=()

    # List of filenames from the first column
    local files=(
        "$results_directory/batch_1_double_glycine_triplet_motif.fasta"
        "$results_directory/batch_2_low_complexity.fasta"
        "$results_directory/batch_3_binary_hydrophobicity.fasta"
        "$results_directory/batch_4_high_diversity.fasta"
        "$results_directory/batch_5_APD_position_specific_block_motif.fasta"
        "$results_directory/batch_6_APD_vertical_YCN_motif.fasta"
        "$results_directory/batch_7_NCBI_IPG_prokaryotic_motif.fasta"
        "$results_directory/batch_8_foldseek_analysis_from_batch_1_to_7.fasta"
        "$results_directory/batch_9_association_analysis_from_batch_1_to_7.fasta"	
	"$results_directory/batch__10_logistic_regression_from_batch_1_to_7.fasta"
        "$results_directory/combo_batch_1_to_7.fasta"
	"$results_directory/combo_batch_8_to_10.fasta"
        "$results_directory/file_1_nucleotides.fasta"
        "$results_directory/file_2_peptides.fasta"
        "$results_directory/file_3_peptides_renamed.fasta"
        "$results_directory/file_4_peptides_deduplicated.fasta"
        "$results_directory/file_5_peptides_oneplus_methionine.fasta"
        "$results_directory/file_6_peptides_methionine_cut.fasta"
        "$results_directory/file_7_peptides_trimmed.fasta"
        "$results_directory/file_8_peptides_tripeptide_filtered.fasta"
        "$results_directory/file_9_peptides_physicochemical.fasta"
	"$results_directory/final.fasta"
	"$results_directory/moreau_broto_descriptors.csv"
	"$results_directory/secondary_structure_analysis.csv"
	"$results_directory/tertiary_structure_analysis.txt"
        "log.txt"
    )

    # Check each file
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            all_files_exist=false
            missing_files+=("$file")
        fi
    done

    # Output result
    if [ "$all_files_exist" = true ]; then
	#skip
	:	
    else
        echo "[ERROR] Missing files:"
        for missing_file in "${missing_files[@]}"; do
            echo "$missing_file"
        done
    fi
}

# Extract open reading frames (ORFs)
getorf -find "$search_type" -table "$codon_table" -minsize "$min_orf_length" -maxsize "$max_orf_length" -sequence "$genome" -outseq "$nucleotides" >> log.txt 2>&1
if [ ! -s "$nucleotides" ]; then
    echo "[INFO] Exiting. No ORFs found."
    exit 1
else
    log_message "Extracted open reading frames ranging from $min_orf_length to $max_orf_length basepairs."
    # Translate nucleotide sequences to peptides
    transeq -table "$codon_table" -sequence "$nucleotides" -outseq "$peptides" >> log.txt 2>&1
    log_message "Translated nucleotide sequences using codon table $codon_table."
fi

# Rename peptide fasta headers
fasta_doctor_x86_64 "$peptides" --rename --unwrap
mv output.fasta "$renamed_peptides"
log_message "Renamed peptide fasta headers."

# Deduplicate peptide sequences
seqkit rmdup -s -i "$renamed_peptides" -o "$deduplicated_peptides" >> log.txt 2>&1
log_message "Removed duplicate peptide candidates."

# Retain peptides with at least one methionine
seqkit grep -P -p 'M' -s "$deduplicated_peptides" > "$methionine_peptides"
log_message "Retained peptides with at least one methionine residue."

# Cut peptides up to the first methionine
awk '/^>/ {print; next} {print substr($0, index($0, "M"))}' "$methionine_peptides" > "$cut_peptides"
log_message "Cut peptides up to first methionine residues."

# Trim peptides to a minimum length of 10 amino acids
seqkit seq -g -m 10 "$cut_peptides" > "$trimmed_peptides"
log_message "Peptides trimmed to a minimum length of ten amino acid residues."

# Remove sequences with tripeptides not present in the reference
seqkit grep -s -v -f "$tripeptide_filter" "$trimmed_peptides" -o "$tripeptide_peptides" >> log.txt 2>&1
log_message "Removed sequences with tripeptides not present in the APD reference."

# Calculate physicochemical properties
headers_in_tripeptides=$(cat $tripeptide_peptides | grep "^>" | wc -l)
if [ "$headers_in_tripeptides" -eq 0 ]; then
    echo "[INFO] Exiting. Not enough peptides to carry out physicochemical analysis."
    exit 1
fi
log_message "Calculating physicochemical properties for $headers_in_tripeptides peptides."
Rscript "$physicochemical_script" "$tripeptide_peptides" "$APD_properties" "$pipeline_temp" >> log.txt 2>&1
seqkit grep -f "$pipeline_temp" "$tripeptide_peptides" -o "$physicochemical_peptides" >> log.txt 2>&1
rm "$pipeline_temp"
log_message "Removed sequences that do not fall within the desired physicochemical range."

# Scan with double glycine triplet motif
seqkit grep -P -s -r -p '"GGG[^G]{1,}GGG"' "$physicochemical_peptides" > "$batch_1"
modify_fasta_headers "_batch_1" "$batch_1"
log_message "Scanned with double glycine triplet motif."

# Identify low complexity peptides
pfilt "$physicochemical_peptides" | seqkit grep -s -p X | seqkit seq -n > "$pipeline_temp"
seqkit grep -f "$pipeline_temp" "$physicochemical_peptides" -o "$batch_2" >> log.txt 2>&1
rm "$pipeline_temp"
modify_fasta_headers "_batch_2" "$batch_2"
log_message "Identified low complexity peptides."

# Identify binary hydrophobicity candidates
python "$hydrophobicity_script" "$physicochemical_peptides" "$pipeline_temp"
seqkit grep -P -s -r -p '"HXXHHXXHHX"' "$pipeline_temp" | seqkit seq -n > "$pipeline_temp2"
seqkit grep -f "$pipeline_temp2" "$physicochemical_peptides" -o "$batch_3" >> log.txt 2>&1
rm "$pipeline_temp" "$pipeline_temp2"
modify_fasta_headers "_batch_3" "$batch_3"
log_message "Identified binary hydrophobicity candidates."

# Identify high diversity candidates
python "$diversity_script" "$physicochemical_peptides" "$batch_4"
modify_fasta_headers "_batch_4" "$batch_4"
log_message "Identified high diversity candidates."

# Scan with APD position-specific block motif
seqkit grep -P -s -r -p '"[AGV][AG][EKR].*[ACK][ILV].*[GK].C"' "$physicochemical_peptides" > "$batch_5"
modify_fasta_headers "_batch_5" "$batch_5"
log_message "Scanned with APD position-specific block motif."

# Scan with APD vertical YCN motif
seqkit grep -P -s -r -p '"YCN"' "$physicochemical_peptides" > "$batch_6"
modify_fasta_headers "_batch_6" "$batch_6"
log_message "Scanned with APD vertical YCN motif."

# Scan with NCBI IPG prokaryotes motif
seqkit grep -P -s -r -p '"[M]..*[G].[G].[G]..*[R]..*[G]..*[P]..*[G]..*[RK]..*[EQ]"' "$physicochemical_peptides" > "$batch_7"
modify_fasta_headers "_batch_7" "$batch_7"
log_message "Scanned with NCBI IPG prokaryotes motif."

# Combine batches
cat $results_directory/batch* > "$batches_combined"

# Retrieve PDBs
headers_in_fasta=$(cat $batches_combined | grep "^>" | wc -l)
if [ "$headers_in_fasta" -eq 0 ]; then
    echo "[INFO] Exiting. Not enough peptides to generate PDBs."
    exit 1
fi
log_message "Generating PDBs for $headers_in_fasta candidate AMPs."
bash "$pdb_curl" "$batches_combined" >> log.txt 2>&1
find $results_directory/pdbs/ -type f -size -100c -print -delete | wc -l | xargs echo "[INFO] Number of PDBs lost due to connection issues:"

#DSSP conversion
for f in $results_directory/pdbs/*.pdb; do mkdssp "$f" "${f%.pdb}.dssp"; done
python "$dssp_script" "$results_directory/pdbs/" "$results_directory/secondary_structure_analysis.csv"
python "$assoc_script" "$APD_dssp" "$candidate_dssp" "$dssp_output"
grep -o 'A[0-9]\+B_batch_[0-9]\+' "$dssp_output" > "$pipeline_temp" || touch "$pipeline_temp"
seqkit grep -f "$pipeline_temp" "$batches_combined" -o "$batches_combined_secondary_structure" >> log.txt 2>&1
modify_fasta_headers "_and_batch_9" "$batches_combined_secondary_structure"
rm "$dssp_output"
rm "$pipeline_temp"
log_message "Secondary structure analysis completed [Threshold parameters: Itemset 0.1, Assoc 0.80]."

#Foldseek analysis
foldseek easy-search "$results_directory/pdbs/" "$APD_foldseek_DB" "$foldseek_out" "$results_directory/tmp" >> log.txt 2>&1
rm -r "$results_directory/tmp"
awk '$3 >= 0.5 && $4 >= 10 {gsub(/\.pdb/, "", $1); print $1}' "$foldseek_out" > "$pipeline_temp"
seqkit grep -f "$pipeline_temp" "$batches_combined" -o "$batches_combined_tertiary_structure" >> log.txt 2>&1
modify_fasta_headers "_and_batch_8" "$batches_combined_tertiary_structure"
rm "$pipeline_temp"
log_message "Tertiary structure analysis completed [Homology parameters: Length 10, Identity 0.5]."

# Logistic regression with XGboost
Rscript "$moreau_script" --file "$batches_combined" --label "candidates" --output "$moreau_results" >> log.txt 2>&1
Rscript "$predict_script" "$xgb_boost_model" "$moreau_results" "$predictions" >> log.txt 2>&1
awk -F, '$3 == "AMP" {print $1}' "$predictions" > "$pipeline_temp"
seqkit grep -f "$pipeline_temp" "$batches_combined" -o "$batches_combined_xgboost" >> log.txt 2>&1
modify_fasta_headers "_and_batch_10" "$batches_combined_xgboost"
rm "$pipeline_temp"
rm "$predictions"
log_message "Logistic regression completed [Parameter: 0.05 for AMP classification]."

# Combine batches again and write final candidates file
cat "$batches_combined_secondary_structure" "$batches_combined_tertiary_structure" "$batches_combined_xgboost" > "$batches_combined_2"
seqkit rmdup -s -o "$pipeline_temp" -d "$pipeline_temp2" "$batches_combined_2" >> log.txt 2>&1
seqkit rmdup -s -o "$candidates" "$pipeline_temp2" >> log.txt 2>&1 #refilter duplicates for in case there were more than two
rm "$pipeline_temp"
rm "$pipeline_temp2"
genome_file="${genome##*/}"
awk -v genome_file="$genome_file" '/^>/{printf(">candidate_A%04dB_%s\n", ++i, genome_file); next} {print}' "$candidates" > "$pipeline_temp"
mv "$pipeline_temp" "$candidates"

#Prepare results
seqkit stat $results_directory/*.fasta -o "report_${genome_file%.*}" >> log.txt 2>&1
bash source_files/generate_reports.sh "report_${genome_file%.*}"
rm "report_${genome_file%.*}"
log_message "HTML and CSV reports generated."

# File check and finish
check_files_exist
end_time=$(date +%s)
duration=$((end_time - start_time))
echo "DONE. Time taken: ${duration} seconds."
