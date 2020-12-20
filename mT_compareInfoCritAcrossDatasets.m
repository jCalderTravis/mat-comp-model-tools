function FigureHandles = mT_compareInfoCritAcrossDatasets(AllDSets)
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

% PLANS
% At the moment checks for consistency amoung the fitted models, but it would be
% good to check that the models and their ordering matches for models used for
% fitting, and models used for generating data. (As described in the above
% section, we assume this.)

% Check the same models have been fit to all participants, and in same order
for iD = 1 : length(AllDSets(:))
    mT_findAppliedModels(AllDSets{iD});
end

AllAic = NaN(length(AllDSets), length(AllDSets));
AllBic = NaN(length(AllDSets), length(AllDSets));

for iD = 1 : length(AllDSets)
    DSet = AllDSets{iD};
    
    if ~isempty(DSet.P)
        
        % Collect BIC and AIC data
        [aicData, bicData] = mT_collectBicAndAicInfo(DSet);
        [CritMeans, figH] = mT_plotAicAndBic(aicData, bicData, [], '', false);
        FigureHandles.AicBic = figH;
        
        AllAic(1:length(CritMeans.AIC), iD) = CritMeans.AIC;
        AllBic(1:length(CritMeans.BIC), iD) = CritMeans.BIC;
        
    end
end

% Plot information criterion means across all datasets
FigureHandles.AicModelRecovery = figure;
h = heatmap(AllAic);
title('Mean AIC')
h.GridVisible = 'off';
h.XLabel = 'Data generating model';
h.YLabel = 'Fitted model';
h.ColorbarVisible = 'off';
h.CellLabelFormat = '%.1f';

FigureHandles.BicModelRecovery = figure;
h = heatmap(AllBic);
title('Mean BIC')
h.GridVisible = 'off';
h.XLabel = 'Data generating model';
h.YLabel = 'Fitted model';
h.ColorbarVisible = 'off';
h.CellLabelFormat = '%.1f';

