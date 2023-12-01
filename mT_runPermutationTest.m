function [pValues, sig] = mT_runPermutationTest(testVals, tmpDir)
% Run a threshold-free cluster-based permutation test.

% INPUT
% testVals: [numCases x numSamples] array. Each row is an independent case,
%   and each column gives a measurement from that case. It is assumed that
%   the columns are ordered such that adjacent columns in testVals are to 
%   be treated as adjacent for the purposes of computing clusters.
% tmpDir: str. Filepath to use for saving temporary files.

% OUTPUT
% pValues: [numSamples x 1] vector of scalar. Gives p-value associated 
%   with each point.
% sig: [numSamples x 1] vector of bool. Gives significance (at 0.05 level)
%   associated with each point. 

numCases = size(testVals, 1);
numSamples = size(testVals, 2);

tmpName1 = [tempname(tmpDir) '.mat'];
tmpName2 = [tempname(tmpDir) '.mat'];

save(tmpName1, 'testVals', '-v7')
EnvInfo = mT_findEnvInfo();
[toolboxPath, ~, ~] = fileparts(mfilename('fullpath'));

system([toolboxPath '\mT_runPermutationTest.bat ' ...
        '"' tmpName1 '" "' ...
        tmpName2 '" "' ...
        EnvInfo.CondaActivate '" ' ...
        EnvInfo.CondaEnv ' ' ...
        toolboxPath])

results = load(tmpName2);
pValues = results.cluster_pv;
assert(isequal(size(pValues), [numSamples, 1]));

sig = pValues < 0.05;