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

### run directory
ccsdir=`printf "%s/samples/%05i" $root $sampleId`
rundir=`printf "%s/samples/%05i/mutation" $root $sampleId`

### call mutations for CCS reads
echo ""
for strand in fwd rev
do
    ### strand-specific run directory
    echo ""
    mkdir -p $rundir/$strand
    cd $rundir/$strand
    echo "Task 1 ($strand) completed at $(date)"

    ### copy and index reference fasta
    echo ""
    cp "$reference" reference.fasta
    echo "Task 2 ($strand) completed at $(date)"

    ### align reads
    echo ""
    pbmm2 align reference.fasta $ccsdir/subreads_ccs.$strand.bam aligned_reads.bam -j 8 -N 1
    echo "Task 3 ($strand) completed at $(date)"

    ### call mutations
    echo ""
    $root/bin/ccs2-mutations.pl aligned_reads.bam reference.fasta >variants.csv
    echo "Task 4 ($strand) completed at $(date)"

    ### pacbio read stats
    echo ""
    $root/bin/bam2csv.pl $ccsdir/subreads_ccs.$strand.bam zmws.csv
    echo "Task 5 ($strand) completed at $(date)"

    ### compress
    echo ""
    7za a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on variants.csv.7z variants.csv
    7za a -t7z -m0=lzma -mx=9 -mfb=64 -md=32m -ms=on zmws.csv.7z zmws.csv
    echo "Task 6 ($strand) completed at $(date)"

    ### cleanup
    echo ""
    rm -f reference.*
    rm -f variants.csv
    rm -f zmws.csv
    echo "Task 7 ($strand) completed at $(date)"
done

echo ""
echo "Finished on $(date)"
