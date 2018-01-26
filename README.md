# TopHat2
## October 30, 2017
Modified and designed by Zachary H Lemmon (<zlemmon@cshl.edu>). 

The "ParameterFile" is required before running the ./prepTh2.sh script. The format is a tab-delimited file with a single line per sample that gives the information needed to run tophat2 alignment, jbrowse bigwig file generation, junction file generation, and htseq-count.

After Tophat2 has been run you can produce merged output with the ~/bin/merge-counts file in ZHL home/bin directory.

After Tophat2 run can merge the bigWig (.bw) files in the "JBrowse_dat" directory using the mergebw.sh script. Need to modify the line to capture multi-sample bigwigs. Wont work on single samples.

Before running the scripts:
1) The experiment SampleInfo file needs to be copied to the base directory and modified into a "ParameterFile" for parallel submission of the samples to cluster. ***Should include only samples you want to quantify
2) Make the ParameterFile from SampleInfo.
3) Use just the filename for compressed XXXXXXXXX.fastq.gz files. Follow best practices in terms of I/O. Use hpc/data for many samples at once and maybe nlsas/data for single/low throughput processing.
4) Make sure basedir is the directory containing all reads. Only remove them after done if you want to! Make sure this is set correctly.
5) Ensure the appropriate bowtie2 indexes and annotation gff3 files have been made in $HOME/indexes
6) This script file itself needs to be in working directory and submitted with qsub 

### Secondary outputs
If adding the junctions.bed file to jbrowse for visualization of exon-exon junctions by sashimiplot plugin, need to adjust the start/stop positions by the "blockSizes" as the flatfile-to-json.pl script of JBrowse does not properly account for it. The following awk one liner has been incorporated into the *ParaTh2.sh script.

awk 'BEGIN{FS="\t";OFS="\t"}FNR==1{print;next}{adjust=$11;split(adjust,adjustarr,",");printf("%s\t%s\t%s",$1, $2+adjustarr[1], $3-adjustarr[2]);for(i=4;i<=NF;i++){printf("\t%s",$i)};printf("\n")}' junctions.bed > adjusted_junctions.bed

Manually add tophat_out_\*/adjusted_junctions.bed to the jbrowse by doing the following:
1. copy the tophat_out\*/adjusted_junctions.bed to /sonas-hs/lippman/nlsas/data/sollab_files/jbrowse/data/data/raw/tomato\*/
2. convert to json with bin/flatfile-to-json.pl. This will be done on sollab from the JBrowse-1.12.1 directory.

```bash
#Example command: 
bin/flatfile-to-json.pl --bed data/data/raw/tomato*/ADJUSTED_JUNCTIONS.bedFILE --trackLabel 'uniqueNoSpaceString' --key 'string with possible spaces to display next to track in browser' --out data/data/json/tomato\*/ --trackType 'SashimiPlot/View/Track/Sashimi'
```

3. manually add the metadata using vi to the trackList.json stanza. Should look something like the following.

```json
       "metadata" : {
         "Type" : "junction",
         "Pi" : "Lippman",
         "Experiment" : "the long description to display in trackSelector",
         "Trackid" : "trackXX"
       }
```
