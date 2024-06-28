#!/bin/bash

if [ "$#" -ne 8 ]; then
    echo "Usage: $0 -a amplicon -s sampleId -c collectionPathUri -p threads"
    exit 1
fi

while getopts "a:s:c:p:" opt; do
  case $opt in
    a) amplicon="$OPTARG" ;;
    s) sampleId="$OPTARG" ;;
    c) collectionPathUri="$OPTARG" ;;
    p) threads="$OPTARG" ;;
    \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
  esac
done

root=`pwd`
reference="$root/references/$amplicon/sequence/$amplicon.fasta"

### create run directory
rundir=`printf "%s/samples/%05i" $root $sampleId`
echo $rundir
mkdir -p $rundir

### switch to working directory
cd $rundir
echo "Task 1 completed at $(date)"

### look up sequencing data
echo ""
raw_bam=`find "$collectionPathUri" -name "*.bam"`

cmd="ln -s $raw_bam movie.subreads.bam"
echo $cmd && $cmd && \
echo "Task 2 completed at $(date)"

echo ""
cmd="pbmm2 align "$reference" "$raw_bam" aligned_reads.bam -j $threads -N 1"
echo $cmd && $cmd && \
echo "Task 3 completed at $(date)"

### extract mapping direction
echo ""
$root/bin/ccs2-map.pl aligned_reads.bam | bzip2 - > clusters.csv.bz2
echo "Task 4 completed at $(date)"

### split forward and reverse reads
echo ""
$root/bin/ccs2-split.pl movie.subreads.bam clusters.csv.bz2
echo "Task 5 completed at $(date)"

### strand-specific CCS reads
for strand in fwd rev
do
    ### convert to bam
    echo ""
    samtools view -Sb subreads.${strand}.sam > subreads.${strand}.bam
    echo "Task 6 ($strand) completed at $(date)"
    
    ### build ccs
    echo ""
    ccs --reportFile=subreads_ccs.${strand}.csv --logFile=subreads_ccs.${strand}.log --num-threads=$threads --minPasses=1 subreads.${strand}.bam subreads_ccs.${strand}.bam
    echo "Task 7 ($strand) completed at $(date)"
done

### cleanup
echo ""
rm -f movie.*
rm -f subreads.*
rm -f aligned_reads.*
rm -f clusters.csv.bz2
echo "Task 8 completed at $(date)"

echo ""
echo "Finished on $(date)"
