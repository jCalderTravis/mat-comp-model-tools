function [AllDSets, FigureHandles] = mT_analyseClusterResults(directory, ...
    paramPlotsModel, removeStartCand, allowMissingData, alreadyUnpacked)
% Run the main analysis for some cluster results

% INPUT
% directory: string. Where to look for results files from the cluster.
% paramPlotsModel: double. Plots the fitted parameter's for this model
% removeStartCand: boolean. Should the candidates used to select the
% starting location be retained. You may not want to retain them if you have run
% lots of fits, as they can take up a substantial proportion of memory.
% allowMissingData: boolean. If false, and there is a fit result missing an
% error is raised.
% alreadyUnpacked: boolean. Have the results from the cluster aleady been 
% upacked. If true, skips the upacking of the results files.

% OUTPUT
% AllDSets: cell array. Each element is one of the datasets that was found, with
% the results of the fitting on the cluster attached.
% FigureHandles: Structure containing figure handles for key figures

DataSets = dir([directory, '\_*_DataStruct.mat']);
if isempty(DataSets)
    error('No datasets found')
end

AllDSets = cell(length(DataSets), 1);
for iD = 1 : length(DataSets)
    
    dsetFilename = strcat(DataSets(iD).folder, '/', DataSets(iD).name);
    Loaded = load(dsetFilename);
    DSet = Loaded.DSet;
    
    % Collect cluster results
    if iD > 1; alreadyUnpacked = true; end
    
    DSet = mT_collectResults(DSet, directory, removeStartCand, ...
        allowMissingData, alreadyUnpacked);
    
    % Plot parameter fits
    if ~isempty(DSet.P)
        mT_plotParameterFits(DSet, paramPlotsModel, 'hist', false)
    end
        
    AllDSets{iD} = DSet;
end

FigureHandles = mT_compareInfoCritAcrossDatasets(AllDSets);






