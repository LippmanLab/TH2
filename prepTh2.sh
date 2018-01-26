#!/bin/bash

if [ $# -ne 2 ] ; then echo -ne "Usage: ./prepTh2.sh ProjectName ParameterFile\n\tProjectName: unique string identifying project\n\tParameterFile: tab-delimited file carrying parameters for th2 alignment\n\n"; exit 0 ; fi

# Input a tag for the project
Proj=$1
PF=$2

# Make a log directory and store location to pass to parameter file.
echo "Making log dir..."
mkdir -p log
logdir=(`pwd`)
logdir="$logdir"/log

# Process the SampleInfo into a ParameterFile. Reports...
# Basename	Read1	Read2	Platform	Reference	ReferenceCDS	ReferenceGFF3	NumbMismatches
#echo "Processing ../SampleInfo into a ParameterFile..."
### Modify the awk to properly construct the parameter file.
#awk 'BEGIN{FS="\t"}NR!=1{gsub(/-/,"",$3);base=$1;r1=$9;r2=$10;printf("%s\t%s\t%s\tNextSeq\tSL3.0\tITAG3.10_CDS.fasta\tITAG3.10_gene_models.gff\t2\t/sonas-hs/lippman/hpc/data/clv_RNAseq/\n", base,r1,r2)}' ../SampleInfo > ParameterFile

# Count SampleNumber
echo "Counting samples..."
SampleNumber=(`wc -l $2 | cut -f1`)

# Adjust log line and parallel line in the Proj_ParaTh2.sh script to have the appropriate
# number of parallel processes (number of samples) and the appropriate logdir.
echo "Making "$Proj"_ParaTh2.sh"
awk -v SampleNumber="$SampleNumber" -v logdir="$logdir" -v ParameterFile="$PF" '{if($0 ~ /^SAMPLENUMBER LINE$/) {print "#$ -t 1-" SampleNumber} else if ($0 ~ /^LOGDIR LINE$/) {print "#$ -o " logdir} else if ($0 ~ /^PARAMETERFILE LINE$/) {print "Parameters=$(sed -n -e \"$SGE_TASK_ID p\" " ParameterFile ")"} else {print}}' Proj_ParaTh2_v3.sh > "$Proj"_ParaTh2.sh
chmod a+x "$Proj"_ParaTh2.sh

