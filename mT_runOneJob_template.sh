#!/bin/bash

#SBATCH --nodes=1
#SBATCH --time=50:00:00
#SBATCH --job-name=fit-ml
#SBATCH --mail-type=NONE


# INPUT
# $1 directory. All relevant MATLAB scripts should be in the folder 
#    directory/scripts or a subfolder of this directory
# $2 file name of the job to run
# $3 Are we starting a new fit or resuming and old one ("0" or "1")

umask 077 

jobDirectory="$1"
filename="$2"
resuming="$3"

# Set a unique folder for this job's matlab parpool data
jobTempDir="$jobDirectory"/$SLURM_JOB_ID
mkdir "$jobTempDir"

# Need to provide matlab input as a string
in1="'$jobDirectory'"
in2="'$filename'"
in3="'$resuming'"

module load matlab/2018b

matlab -nodisplay -nosplash -r "mT_runOnCluster($in1, $in2, $SBATCH_TIMELIMIT, $in3)"


