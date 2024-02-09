function [AllDSets, FigureHandles] = mT_analyseClusterResults(directory, ...
    paramPlotsModel, removeStartCand, allowMissingData, alreadyUnpacked, ...
    varargin)
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
% varargin{1}: numModels long cell array of model names to use instead of 
% simply numebering the models (only used for some plots)
% varargin{2}: boolean. Set to true if running a model recovery. Additional
% plots will be produced. Default is false.

% OUTPUT
% AllDSets: cell array. Each element is one of the datasets that was found, with
% the results of the fitting on the cluster attached.
% FigureHandles: Structure containing figure handles for key figures

% HISTORY
% Reviewed 2020

% Process input
if (~isempty(varargin)) && (~isempty(varargin{1}))
    modelNames = varargin{1};
else
    modelNames = [];
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    isModelRecov = varargin{2};
else
    isModelRecov = false;
end


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

if isModelRecov
    FigureHandles = mT_compareInfoCritAcrossDatasets(AllDSets, modelNames);
else
    FigureHandles = [];
end

% If there is only a single dataset, plot the AIC and BIC results for this
% dataset
if (length(AllDSets) == 1) && (length(AllDSets{1}.P(1).Models) > 1)
    DSet = AllDSets{1};
    [aicData, bicData] = mT_collectBicAndAicInfo(DSet);
    [~, thisFig] = mT_plotAicAndBic(aicData, bicData, [], '', false);
    FigureHandles.AicBic = thisFig;
end





