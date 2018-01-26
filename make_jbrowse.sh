#!/bin/bash
#$ -cwd
#$ -j y
#$ -l m_mem_free=5G

### sp5G_TM only one file so can't do it here now.

stages=($( ls -d tophat_out* | awk '{gsub(/tophat_out_/,"",$1);gsub(/_[0-9]+$/,"",$1);arr[$1]++}END{for(key in arr){printf("%s ",key)}}' ))

#for stage in "${stages[@]}" ; do echo $stage ; done

echo "Starting bigwig merge..." ; date
for stage in "${stages[@]}" ; do
	echo $stage
	bwfiles=($(ls JBrowse_dat/"$stage"*bw))
	if  [[ "${#bwfiles[@]}" -eq 1 ]] ; then echo "Only one bigwig file, already merged? skipping." ; continue ; fi
	bigWigMerge JBrowse_dat/"$stage"*bw "$TMPDIR"/"$stage".bedGraph
	bedGraphToBigWig "$TMPDIR"/"$stage".bedGraph ~/indexes/SL3.0/SL3.0_chromsizes.txt JBrowse_dat/"$stage".bw
done
echo "Done with bigwig merging" ; date

echo "Starting splice junction bedfile merge..." ; date
for stage in "${stages[@]}" ; do
	echo $stage
	cat tophat_out_$stage*/junctions.bed | tbed2juncs | combineJuncs > JBrowse_dat/"$stage".juncs
	head -n1 JBrowse_dat/"$stage".juncs > JBrowse_dat/"$stage"_junctions.bed
	tail -n +2 JBrowse_dat/"$stage".juncs | sort -k1,1 -k2,2n >> JBrowse_dat/"$stage"_junctions.bed
	rm -f JBrowse_dat/"$stage".juncs
done
echo "Done with splice junction bedfile merging" ; date

