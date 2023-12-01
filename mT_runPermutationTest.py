""" Script for running threshold-free cluster-based permutation test using
data from matlab. 

INPUT ARGS
1: str. Filepath of a file containing a matlab array of test values. The
    array should have shape numCases x numSamples] array. Each row is an 
    independent case, and each column gives a measurement from that case. 
    It is assumed that the columns are ordered such that adjacent columns 
    in testVals are to be treated as adjacent for the purposes of 
    computing clusters.
2: str. Filepath to use for saving the results of the permutation test.
"""

import sys
import scipy
import mne 

loadname = sys.argv[1]
savename = sys.argv[2]

loaded = scipy.io.loadmat(loadname)
testVals = loaded['testVals']

_, _, cluster_pv, _ = mne.stats.permutation_cluster_1samp_test(testVals, 
                                threshold={'start':0, 'step':0.005},
                                adjacency=None,
                                verbose=False)

scipy.io.savemat(savename, {'cluster_pv': cluster_pv}, oned_as='column')