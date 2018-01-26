#!/bin/bash
#$ -cwd
#$ -j y
#$ -l m_mem_free=5G

### sp5G_TM only one file so can't do it here now.

for stage in clvM82_MVM clv1_TM clv2_TM clv3cle9_MVM clv3_TM clv13_MVM clv12_MVM clv3_MVM clv12_TM clv13_TM clv2_MVM sp5g_MVM clv3cle9_TM clvM82_TM clv1_MVM ; do
	echo $stage
	bigWigMerge JBrowse_dat/"$stage"* "$TMPDIR"/"$stage".bedGraph
	bedGraphToBigWig "$TMPDIR"/"$stage".bedGraph ~/indexes/SL3.0/SL3.0_chromsizes.txt JBrowse_dat/"$stage".bw
done

