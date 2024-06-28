#!/bin/bash

if [ "$#" -lt 2 ] || ( [ "$2" != "view" ] && [ "$2" != "consensus" ] && [ "$2" != "chimeric" ] && [ "$2" != "mutation" ] && [ "$2" != "summary" ] && [ "$2" != "tabulate" ] )
then
    echo "usage: $0 samples.csv view"      >&2
    echo "       $0 samples.csv consensus" >&2
    echo "       $0 samples.csv chimeric"  >&2
    echo "       $0 samples.csv mutation"  >&2
    echo "       $0 samples.csv summary"   >&2
    echo "       $0 samples.csv tabulate"  >&2
    exit 1
fi

PROJDIR=`dirname $0`

samples=$(realpath $1)
command=$2
howtorun=$3 #either 'local', 'dryrun', 'qsub'
threads=${4:-1}
memory=${5:-4g}

# set environment value for $SGEQ and $SGEP
resource="-l vf=$memory,num_proc=$threads  -binding linear:$threads -q $SGEQ -P $SGEP"

cd $PROJDIR

if [ "$command" == "tabulate" ] ; then
    echo "SampleID,Enzyme,Amplicon,Input,Yield,collectionPathUri,GroupID,AA,AC,AT,AG,CA,CC,CT,CG,TA,TC,TT,TG,GA,GC,GT,GG,Deletion,Insertion"
fi

while read line
do
    if [[ ! $line =~ "SampleID" ]]
    then
		### extract SampleID, Amplicon, and data path for each sample
		sampleId=`echo $line | cut -d, -f1`
		amplicon=`echo $line | cut -d, -f3`
		collectionPathUri=`echo $line | cut -d, -f6 | xargs -n1 realpath`
		if [ "$command" == "view" ]
		then
			### preview run info
			echo ""
			echo "sampleId=$sampleId"
			echo "amplicon=$amplicon"
			echo "collectionPathUri=$collectionPathUri"
		else
			if [ "$command" != "tabulate" ] ; then
				logdir=`printf "%s/samples/%05i" $PROJDIR $sampleId`
				mkdir -p "$logdir"
					
				cmd="$PROJDIR/scripts/ccs2-$command.sh -a $amplicon -s $sampleId -c $collectionPathUri -p $threads"

				if [ "$howtorun" == "qsub" ];then
					echo "Run on SGE: $cmd"
					qsub -V -cwd $resource -N "ccs-$sampleId" -o $logdir/$command.log -j yes $cmd
				else
					cmd="bash $cmd"
					if [ "$howtorun" == "local" ];then
						echo "Run on local: $cmd" && $cmd
					else
						if [ "$howtorun" == "localbg" ];then
							echo "Run on local: $cmd" && $cmd &
						else
							echo "Dryrun(no run): $cmd"
						fi
					fi
				fi 
			else
				rundir=`printf "%s/samples/%05i/summary" $PROJDIR $sampleId`
				echo $line | tr '\n' ","
				tail --lines 1 $rundir/summary.csv
			fi
		fi
    fi
done < $samples
