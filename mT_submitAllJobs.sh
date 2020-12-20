#!/bin/bash

# Submits all jobs which don't have an associated results file.

# INPUT
# $1    Directory in which to look for jobs. All relevant scripts should be in a
#       folder (or subfolder) of this directory named "scripts". Resutls will be 
#       saved here.

jobDirectory=$1

# Loop through all job files in the direcotry
for filename in $jobDirectory/*job.mat; do

	# Does this job already have a results file or a partial results file?
	rootName=${filename:0:$((${#filename} - 7))}
	resultFile=$rootName"1_result_PACKED.mat"
    	partialFile=$rootName"1_result_PARTIAL.mat"

	if [ ! -f "$resultFile" ] 
	then
            if [ ! -f "$partialFile" ]
	   then
            
                # Submit the job
                sbatch ./mT_runOneJob.sh "$jobDirectory" "$filename" "0"
                echo "Starting ..."
                echo "$filename"
                echo " "

            else

                # Resume the job
                sbatch ./mT_runOneJob.sh "$jobDirectory" "$partialFile" "1"
                echo "Resuming ..."
                echo "$filename"
                echo " "

            fi

	fi

done
