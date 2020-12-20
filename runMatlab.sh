#!/bin/bash

umask 077     

module load matlab/R2018b

matlab -nodisplay -nosplash 
# -r "mT_runOnCluster($in1, $in2, $in3)"
