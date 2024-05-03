# DESCRIPTION
A software pipeline that takes as input a multi-fasta file containing any type of nucleotide sequences, extracts open reading frames (ORFs) from the nucleotide sequences, translates the ORFs to peptides, and through multiple filtering steps derives candidate antimicrobial peptides (AMPs). A single bacterial genome can be processed in less than five minutes but larger sequence sets can lead to memory and processor capacities being exceeded (see [time complexity analysis](#pipeline-time-complexity-analysis)).

:zap: _"This wee script is a canny tool for rummaging through heaps of genetic code to root out what might just be the next big thing in fighting germs. Ye pop in a file crammed with DNA sequences and it gets to work sifting through to find the bits that could turn into proteins – those are your open reading frames, or ORFs. It then translates these ORFs into strings of amino acids to see if any might be shaped like the sort of peptides that have a knack for knocking out baddies like bacteria."_

# PIPELINE FLOW DIAGRAM
![Flow_diagram](source_files/images/flow_diagram.gif)
Candidate AMPs are called using ten distinct methods. The batches that the first seven methods lead to are collectively referred to as the primary candidate set. The primary candidates from batch one through seven are then filtered using three more methods in a second round of candidate selection using only the primary candidate set as input. Candidates that pass this second round are collectively referred to as the secondary candidate set. Candidates that appear at least twice in the secondary candidate set are referred to as the tertiary candidate set. Members of the tertiary candidate set are guaranteed to have been flagged as candidate AMPs by at least three methods of the pipeline. Candidates that are called by multiple methods are intuitively more likely to be AMPs and as such are considered priority candidates for wet lab validation, but the full set of called candidates always remains the primary candidate set.

# EVALUATION
![Evaluation](source_files/images/evaluation.gif)
The pipeline was evaluated using [AmpGram](https://doi.org/10.3390/ijms21124310). Controls showed that the pipeline has a different AMP candidate selection strategy than AmpGram. Evaluation of the pipeline on real and fake datasets showed that candidates from a concatenation of the following real genomes are more likely to be AMPs than candidates from fake genomes that mimic the real genomes in number of contigs and random nucleotides per contig. ORFs from real genomes are also more likely to encode AMPs than ORFs from fake genomes.

_Actinoplanes philippinensis_, 
_Amycolatopsis fastidiosa_, 
_Bacillus subtilis_, 
_Companilactobacillus crustorum_, 
_Enterococcus faecalis_, 
_Enterococcus faecium_, 
_Escherichia coli K12_, 
_Escherichia coli O157H7_, 
_Klebsiella pneumoniae_, 
_Lacticaseibacillus paracasei_, 
_Lactobacillus curvatus_, 
_Lactobacillus helveticus_, 
_Lactococcus lactis_, 
_Latilactobacillus sakei_, 
_Ligilactobacillus salivarius_, 
_Loigolactobacillus coryniformis_, 
_Microbispora corallina_, 
_Pediococcus acidilactici_, 
_Pediococcus pentosaceus_, 
_Rhodococcus jostii_, 
_Staphylococcus epidermidis_, 
_Staphylococcus gallinarum_, 
_Staphylococcus simulans_, 
_Staphylococcus warneri_, 
_Streptococcus bovis_, 
_Streptococcus mutans_, 
_Streptomyces bottropensis_

# INSTALLATION (see [demo](#demo))
The mamba package manager is needed to resolve installation of an older version of libboost for dssp:  

```
conda install conda-forge::mamba
```

Then set up the conda environment as follow:  

```
git clone https://github.com/Werner0/antimicrobial_peptides.git
cd ./antimicrobial_peptides/setup
mamba env create -f requirements.yaml
conda activate candidates
bash configure_pfilt.sh
```

# USAGE (see [demo](#demo))
The pipeline is designed for bacterial genome analysis but will take any nucleotide sequences as input. It will run using a sample nucleotide set consisting of two concatenated genomes (_Escherichia coli_ and _Sorangium cellulosum_) if no input is provided.

```
bash end_to_end.sh [nucleotides.fasta|.fna]
```

More example genomes are available in ./source_files/genomes/

# OUTPUT
+ HTML and CSV reports with summary statistics of batches and intermediary files:
  +  Batch 1: Candidates containing the _GGG[^G]{1,}GGG_ motif. This motif is disproportionately present in the [APD reference set](https://aps.unmc.edu/).
  +  Batch 2: Low complexity candidates including those with coiled-coil, transmembrane and WD repeat signatures.
  +  Batch 3: Candidates containing the _HXXHHXXHHX_ motif after binary hydrophobicity conversion, where the amino acid residues A, I, L, M, F, W & V are represented by H, the amino acid residues S, T, C, N, Q & Y are represented by P, and all others by X. This motif is the most frequent 10-mer at the k-peptide frequency peak of the APD reference set.
  +  Batch 4: High diversity candidates containing at least one of each of the twenty standard amino acid residues.
  +  Batch 5: Candidates containing the _[AGV][AG][EKR].*[ACK][ILV].*[GK].C_ motif. This motif was obtained by [MSA analysis](source_files/dead_code/msa_count.py) of within peptide compositional frequencies of the APD reference set.
  +  Batch 6: Candidates containing the YCN motif. This motif was obtained by MSA analysis of across peptide compositional frequencies of the APD reference set.
  +  Batch 7: Candidates containing the _[M]..*[G].[G].[G]..*[R]..*[G]..*[P]..*[G]..*[RK]..*[EQ]_ motif. This motif was obtained by MSA analysis of within peptide compositional frequencies of an NCBI IPG prokaryotic AMP set.
  +  Batch 8: Candidates with tertiary peptide structure homology to validated antimicrobial peptides in the APD reference set.
  +  Batch 9: Candidates with a similar itemset frequency as the APD reference set in terms of secondary structures including alpha helices (3-10 and pi), beta sheets (bridged and extended), hydrogen bond turns and loops.
  +  Batch 10: Candidates derived from binary logistic regression using [Moreau-Broto autocorrelation descriptors](https://github.com/nanxstats/protr/blob/master/R/desc-04-MoreauBroto.R) (normalized average hydrophobicity, average flexibility, polarizability, free energy in water, accessible surface area (as tripeptides), residue volume, steric hindrance, and relative mutability).
  +  File 1: Extracted ORFs.
  +  File 2: ORFs translated to peptides.
  +  File 3: Peptides with renamed headers.
  +  File 4: Deduplicated peptides.
  +  File 5: Peptides with at least one methionine residue.
  +  File 6: Peptides left-trimmed up to first methionine.
  +  File 7: Peptides with a minimum length of 10 residues.
  +  File 8: Peptides filtered for tripeptides that are not seen in the APD reference set.
  +  File 9: Peptides that meet the 95th percentile physicochemical distribution range of the APD reference set in terms of their counts of individual amino acid residue membership to the following classes: tiny, small, aliphatic, aromatic, non-polar, polar, charged, basic and acidic. 
  +  Combo Batch 1 to 7: Merge of batches 1 to 7 ("primary candidate set").
  +  Combo Batch 8 to 10: Merge of batches 8 to 10 ("secondary candidate set").
  +  Final: Priority AMP candidates ("tertiary candidate set").
+ Secondary structure analysis: ./output/secondary_structure_analysis.csv (for Batch 9).
+ Tertiary structure analysis: ./output/tertiary_structure_analysis.txt (for Batch 8).

# LOGGING
+ Log written to ./log.txt  
+ For more verbose logging, uncomment `#set -x` on line 3 in ./end_to_end.sh

# DEMO
![DEMO](source_files/images/demo.gif)

# PIPELINE TIME COMPLEXITY ANALYSIS
![BigO](source_files/images/time_complexity.gif)
