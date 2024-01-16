function [aicData, bicData] = mT_collectBicAndAicInfo(DSet)
% For a dataset in the standard format, the code pulls
% DSet.P(i).Models(j).BestFit.Bic, or Aic, for all models and participants and
% produces a [numModels x numParticipants] arrays for each.

% HISTORY
% Reviewed 2020

% Check the same models have been applied to all participants, and in same order
mT_findAppliedModels(DSet);

CritData.Aic = NaN(length(DSet.P(1).Models), length(DSet.P));
CritData.Bic = NaN(length(DSet.P(1).Models), length(DSet.P));
crit = {'Aic', 'Bic'};

for iCrit = 1 : length(crit)
    for iPtpnt = 1 : length(DSet.P)
        CritData.(crit{iCrit})(:, iPtpnt) ...
            = mT_stackData(DSet.P(iPtpnt).Models, ...
            @(ModelStruct) ModelStruct.BestFit.(crit{iCrit}));
    end
end

aicData = CritData.Aic;
bicData = CritData.Bic;

% Code test
for iCrit = 1 : length(crit)
    for iP = 1 : length(DSet.P)
        for iM = 1 : length(DSet.P(1).Models)
            assert(isequal(CritData.(crit{iCrit})(iM, iP), ...
                DSet.P(iP).Models(iM).BestFit.(crit{iCrit})));
        end
    end
end