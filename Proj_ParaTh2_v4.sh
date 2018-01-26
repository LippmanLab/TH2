#!/bin/bash
#$ -cwd
#$ -j y
#$ -l m_mem_free=6G
#$ -l tmp_free=100G
SAMPLENUMBER LINE
LOGDIR LINE
#$ -pe threads 8

# Before running the script:
#	1) The experiment SampleInfo file needs to be copied to the base directory and modified into a "ParameterFile" for parallel submission of the samples to cluster. ***Should include only samples you want to quantify
#	2) Make the ParameterFile from SampleInfo.
#	3) Use absolute paths to compressed XXXXXXXXX.fastq.gz files. Follow best practices in terms of I/O. Use hpc/data for many samples at once and maybe nlsas/data for single/low throughput processing.
#	4) Ensure the appropriate bowtie2 indexes and annotation gff3 files ahve been made in $HOME/indexes
#	5) This script file itself needs to be in working directory and submitted with qsub

PATH="$HOME/bin/bowtie2-2.2.3:$HOME/bin/Trimmomatic-0.32:$HOME/bin/samtools-1.3.1/bin:$HOME/bin/fastx_toolkit-0.0.14/bin:$HOME/bin/bowtie-1.1.0:/bin:/usr/bin:$HOME/bin:/opt/hpc/bin"

# Reads in parameters from ParameterFile
PARAMETERFILE LINE
#Parameters=$(sed -n -e "$SGE_TASK_ID p" ParameterFile)
SampleName=$( echo "$Parameters" | awk '{print $1}' )
Read1=$( echo "$Parameters" | awk '{print $2}' )
Read2=$( echo "$Parameters" | awk '{print $3}' )
ReadType=$( echo "$Parameters" | awk '{print $4}' )
Genome=$( echo "$Parameters" | awk '{print $5}' )
TxomeBt2Index=$( echo "$Parameters" | awk '{print $6}' )
Annotation=$( echo "$Parameters" | awk '{print $7}' )
MM=$( echo "$Parameters" | awk '{print $8}' )
basedir=$( echo "$Parameters" | awk '{print $9}' )
keep=$( echo "$Parameters" | awk '{print $10}' )

echo -e "\n######################\n######################\n\nRunning tophat alignment of $SampleName versus $Genome\n"

# Trim reads
echo -e "\n######################\nTrimming $Read1 $Read2 > $SampleName" ; date
PR1="$SampleName"_P1.fastq
PR2="$SampleName"_P2.fastq
UR1="$SampleName"_U1.fastq
UR2="$SampleName"_U2.fastq
if [[ $ReadType == HiSeq || $ReadType == NextSeq ]] ; then 
	java -jar $HOME/bin/Trimmomatic-0.32/trimmomatic-0.32.jar PE -threads 8 $basedir/$Read1 $basedir/$Read2 $TMPDIR/$PR1 $TMPDIR/$UR1 $TMPDIR/$PR2 $TMPDIR/$UR2 ILLUMINACLIP:$HOME/bin/Trimmomatic-0.32/adapters/TruSeq3-PE-2.fa:2:40:15:1:FALSE LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
else 
	java -jar $HOME/bin/Trimmomatic-0.32/trimmomatic-0.32.jar PE -threads 16 $basedir/$Read1 $basedir/$Read2 $TMPDIR/$PR1 $TMPDIR/$UR1 $TMPDIR/$PR2 $TMPDIR/$UR2 ILLUMINACLIP:$HOME/bin/Trimmomatic-0.32/adapters/TruSeq2-PE.fa:2:30:10:1:FALSE LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 TOPHRED33
fi
rm -vf $TMPDIR/$UR1 $TMPDIR/$UR2 # remove unpaired reads
###rm -vf $basedir/$Read1 $basedir/$Read2 # remove raw reads if wanted. ### MAKE SURE THIS ISN'T THE ONLY COPY ###

# tophat2 mapping to Genome
outdir=tophat_out_"$SampleName"
echo -e "\n######################\nAligning $PR1 $PR2 to $Genome. Results in $TMPDIR/$outdir/" ; date
# if doing the --GTF tophat2 guided mode uncomment this section to make tophat2 requisite files...
#echo "Making tophat2 requisite files..."
#tophat2 --GTF=$HOME/indexes/$Annotation --transcriptome-index=./indexes/$TxomeBt2Index $HOME/indexes/$Genome

### Want to add the ReadGroup Information... add the following options '--rg-id readgroupID --rg-sample sampleID --rg-library libraryID --rg-description DescriptionLongNoTab --rg-platform Illumina'
tophat2 --output-dir $TMPDIR/$outdir/ --b2-very-sensitive --read-mismatches $MM --read-edit-dist $MM --min-anchor 8 --splice-mismatches 0 --min-intron-length 50 --max-intron-length 50000 --max-multihits 20 --num-threads 8 "$HOME"/indexes/SL3.0/"$Genome" $TMPDIR/$PR1 $TMPDIR/$PR2
rm -vf $TMPDIR/$PR1 $TMPDIR/$PR2 # remove trimmed fastq

### copy over some of the summary files to keep
echo -e "\n######################\nCopying summary Tophat2 files for $SampleName to ./$outdir/" ; date
mkdir -p ./$outdir
cp -v $TMPDIR/$outdir/align_summary.txt ./$outdir/
cp -v $TMPDIR/$outdir/*bed ./$outdir/
cp -R $TMPDIR/$outdir/logs/ ./$outdir/
cp -v $TMPDIR/$outdir/prep_reads.info ./$outdir/
if [ $keep == 1 ] ; then cp -v $TMPDIR/$outdir/*bam* ./$outdir/ ; fi

# adjusts the junctions.bed file to properly display splice in jbrowse sashimiplot
awk 'BEGIN{FS="\t";OFS="\t"} FNR==1 {print;next} {\
	adjust=$11;split(adjust,adjustarr,",");\
	printf("%s\t%s\t%s",$1, $2+adjustarr[1], $3-adjustarr[2]);\
	for(i=4;i<=NF;i++){printf("\t%s",$i)};\
	printf("\n");\
}' ./$outdir/junctions.bed > ./$outdir/adjusted_junctions.bed
# The adjusted_junctions.bed file can now be added to jbrowse and properly display junctions. Please see README for the more hands on manual work needed to do this.

# sort the bam files
nbamfile=accepted_hits_nsorted.bam
pbamfile=accepted_hits_psorted.bam
infile=accepted_hits.bam
echo -e "\n######################\nName sorting bamfile: $TMPDIR/$outdir/$infile -> $TMPDIR/$nbamfile." ; date
samtools sort -n -O bam -T $TMPDIR/$SampleName -o $TMPDIR/$nbamfile $TMPDIR/$outdir/$infile
echo -e "\n######################\nPosition sorting bamfile: ./$outdir/$infile -> ./$outdir/$pbamfile." ; date
samtools sort -O bam -T $TMPDIR/$SampleName -o $TMPDIR/$pbamfile $TMPDIR/$outdir/$infile
rm -vf $TMPDIR/$outdir/$infile # remove unsorted bam

# counting reads with htseq-count
countfile=accepted_hits_counts
echo -e "\n######################\nCounting reads with htseq-count: ./$outdir/$nbamfile -> ./$outdir/$countfile" ; date
htseq-count --quiet --format=bam --order=name --stranded=no --type=exon --idattr=Parent $TMPDIR/$nbamfile $HOME/indexes/SL3.0/ITAG3.20/$Annotation > ./$outdir/$countfile
rm -vf $TMPDIR/$nbamfile # remove name sorted bam. Keep position sorted bam as it is most compact alignment.

echo -e "\nTophat2 mapping for $SampleName finished" ; date

########
# Make jbrowse data

# Make directory for results.
mkdir -p JBrowse_dat

# make bw file from bam file
echo -e "\n######################\nMaking bedgraph for $TMPDIR/$pbamfile" ; date
genomeCoverageBed -split -bg -ibam $TMPDIR/$pbamfile -g $HOME/indexes/SL3.0/SL3.0_chromsizes.txt > $TMPDIR/"$SampleName".bedgraph
echo -e "\n######################\nConverting bedgraph to bigwig for $SampleName" ; date
bedGraphToBigWig $TMPDIR/$SampleName.bedgraph $HOME/indexes/SL3.0/SL3.0_chromsizes.txt JBrowse_dat/"$SampleName".bw
rm -vf "$TMPDIR"/"$SampleName".bedgraph

echo -e "\n######################\nDone preparing $SampleName bigwig for JBrowse" ; date






