# DESCRIPTION
A software pipeline that takes as input a multi-fasta file containing any type of nucleotide sequences, extracts open reading frames (ORFs) from the nucleotide sequences, translates the ORFs to peptides, and through multiple filtering steps derives candidate anti-microbial peptides. NOTE: A single bacterial genome can be processed in less than five minutes but larger sequence sets can lead to memory and processor capacities being exceeded.

# INSTALLATION
`conda install conda-forge::mamba`  
`cd setup`  
`mamba env create -f requirements.yaml`  
`conda activate candidates`

# USAGE
`bash end_to_end.sh [nucleotides.fasta]`

# OUTPUT
+ Summary of FASTA batches and intermediary files: ./report_input_filename
  +  Batch 1: `GGG[^G]{1,}GGG` motif
  +  Batch 2: Low complexity candidates
  +  Batch 3: `HXXHHXXHHX` motif (after binary hydrophobicity conversion)
  +  Batch 4: High diversity candidates
  +  Batch 5: `[AGV][AG][EKR].*[ACK][ILV].*[GK].C` motif
  +  Batch 6: `YCN` motif
  +  Batch 7: `[M]..*[G].[G].[G]..*[R]..*[G]..*[P]..*[G]..*[RK]..*[EQ]..*` motif
  +  Batch 8: Tertiary peptide structure homologs
  +  Batch 9: Secondary peptide structure homologs
  +  Batch 10: Binary logistic regression candidates
+ Secondary structure analysis: ./output/secondary_structure_analysis.csv  
+ Tertiary structure analysis: ./output/tertiary_structure_analysis.txt  
+ Priority AMP candidates (empty file if none were detected): ./output/final.fasta

# LOGGING
Log written to ./log.txt
