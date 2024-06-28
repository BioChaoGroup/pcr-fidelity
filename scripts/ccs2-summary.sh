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
rundir=`printf "%s/samples/%05i/summary" $root $sampleId`
mkdir -p $rundir
cd $rundir

### tally up mutations
echo ""
sampledir=`printf "%s/samples/%05i" $root $sampleId`
$root/bin/ccs2-summary.pl \
    --np 15 \
    --qv 93 \
    --lb 40 \
    --ub 40 \
    --rlp 0.80 \
    $reference $sampledir >summary.csv 2>summary.log
echo "Task 1 completed at $(date)"

echo ""
echo "Finished on $(date)"
