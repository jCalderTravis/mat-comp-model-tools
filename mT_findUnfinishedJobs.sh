#!/bin/bash

# INPUT
# First input should be the directory in which to look for jobs

# HISTORY
# Reviewed 16.01.2024

searchDir=$1

# Find all jobs
allJobs=$(ls $searchDir/*job.mat)


# Find jobs with results
echo "-------------------------------------------------"
echo "Finished jobs"
echo "-------------------------------------------------"

for i in $allJobs 
do 
	rootName=${i:0:$((${#i} - 7))}
	new=$rootName"1_result_PACKED.mat"

	if [ -f "$new" ] 
	then 
		echo $i

	fi
done


# Find jobs without any results
echo "-------------------------------------------------"
echo "Unfinished jobs"
echo "-------------------------------------------------"

for i in $allJobs 
do 
	rootName=${i:0:$((${#i} - 7))}
	new=$rootName"1_result_PACKED.mat"

	if [ ! -f "$new" ] 
	then 
		echo $i

	fi
done
