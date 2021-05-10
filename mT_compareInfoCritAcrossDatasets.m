function FigureHandles = mT_compareInfoCritAcrossDatasets(AllDSets, ...
                                                          varargin)
% Look at the AIC and BIC for a set of models that have all been fit to a number
% of datasets. Each of the datasets has been generated with one of the models.
% I.e. we are perfoming model recovery.

% INPUT
% AllDSets: Cell array of DSets. Each DSet should have been modeled using the
% same models, in the same order i.e. numbering of the models must be identical.
% The datsets in AllDSets should each have been generated under
% one of the n models used for analysis. The DSet at index i in AllDSets should
% have been generated using model i (where counting is done using the same
% ordering of the models that is used for fitting).
% varargin{1}: numModels long cell array of model names to use instead of 
% simply numebering the models

% Process input
if (~isempty(varargin)) && (~isempty(varargin{1}))
    modelNames = varargin{1};
else
    modelNames = [];
end

% Check the same models have been fit to all participants, and in same order
dataGenModels = cellfun(@(st) st.SimSpec.Name, AllDSets, ...
                        'UniformOutput', false);
for iD = 1 : length(AllDSets(:))
    theseModels = mT_findAppliedModels(AllDSets{iD})';
    if ~isequal(dataGenModels, theseModels)
        error('Model ordering is inconsistent.')
    end
end

% If have any model names, check have one for each model
if ~isempty(modelNames)
    assert(length(modelNames) == length(dataGenModels))
end


AllAic = NaN(length(AllDSets), length(AllDSets));
AllBic = NaN(length(AllDSets), length(AllDSets));

for iD = 1 : length(AllDSets)
    DSet = AllDSets{iD};
    
    if ~isempty(DSet.P)
        
        % Collect BIC and AIC data
        [aicData, bicData] = mT_collectBicAndAicInfo(DSet);
        [CritMeans, ~] = mT_plotAicAndBic(aicData, bicData, [], '', false);
        
        AllAic(1:length(CritMeans.AIC), iD) = CritMeans.AIC;
        AllBic(1:length(CritMeans.BIC), iD) = CritMeans.BIC;
        
    end
end

% Plot information criterion means across all datasets
FigureHandles.AicModelRecovery = figure;
if isempty(modelNames)
    h = heatmap(AllAic);
else
    h = heatmap(modelNames, modelNames, AllAic);
end
title('Mean AIC')
h.GridVisible = 'off';
h.XLabel = 'Data generating model';
h.YLabel = 'Fitted model';
h.ColorbarVisible = 'off';
h.CellLabelFormat = '%.1f';

FigureHandles.BicModelRecovery = figure;
if isempty(modelNames)
    h = heatmap(AllBic);
else
    h = heatmap(modelNames, modelNames, AllBic);
end
title('Mean BIC')
h.GridVisible = 'off';
h.XLabel = 'Data generating model';
h.YLabel = 'Fitted model';
h.ColorbarVisible = 'off';
h.CellLabelFormat = '%.1f';

