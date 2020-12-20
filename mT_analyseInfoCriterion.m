function [ResultsTable, baselinedCrit] = mT_analyseInfoCriterion(infoCrit)
% Takes information criterion values in (numModels)x(numParticipants) array and 
% produces a table containing the mean info criterion, confidence intervals, 
% and for each model, the number of participants for which that model has the
% smallest value of the information criterion.

% OUTPUT
% baselinedCrit: The information criterion with the (overall) best fitting model
% subtracted off

% TESTING
% If pass infoCrit as the string 'test', runs tests instead.

if strcmp(infoCrit, 'test')
    testFun()
    return
end


% Enumerate model numbers
modelNums = [1 : size(infoCrit, 1)]';

% Baseline and aggregate infoCrit
[baselineMean, baselineModel] = min(nanmean(infoCrit, 2));
baselinedCrit = infoCrit - infoCrit(baselineModel, :);
meanInfoCrit = nanmean(baselinedCrit, 2);

assert(isequal(round(meanInfoCrit, 7), ...
    round(nanmean(infoCrit, 2) - baselineMean, 7)))

% Confidence intervals around aggregate
meanCI = NaN(size(infoCrit, 1), 2);
for iModel = 1 : size(infoCrit, 1)
    
    % There are no error bars around the baseline model as all values for the
    % baseline model are zero
    if iModel == baselineModel; continue; end
    
    critVals = baselinedCrit(iModel, :)';
    meanCI(iModel, :) = bootci(10000, @(vals) nanmean(vals), critVals);
    
end

errorAbove = meanCI(:, 2) - meanInfoCrit;
errorBelow = meanCI(:, 1) - meanInfoCrit;

if any(meanCI(:, 2) < meanCI(:, 1)); error('Different ordering assumed.'); end
if any(errorBelow > 0); error('bug'); end

% Switch sign ready for MATLAB error bar function
errorBelow = abs(errorBelow); 

% Number of participants best fit by the model (in case some participants have
% not been fit to any models)
excludedParticipants = all(isnan(infoCrit), 1);
infoCritWithNoNans = infoCrit;
infoCritWithNoNans(:, excludedParticipants) = [];
if any(isnan(infoCritWithNoNans)); error('Bug'); end

% For a particular partipant the best fitting model will have the lowest
% information criterion
[~, bestFit] = min(infoCritWithNoNans); 

numBestFit = NaN(length(modelNums), 1);
for iModel = modelNums'
    numBestFit(iModel) = nansum(bestFit == iModel);
end
assert(sum(numBestFit) == (size(infoCrit, 2)- sum(excludedParticipants)))

ResultsTable = table(modelNums, meanInfoCrit, errorAbove, errorBelow, numBestFit);

end


function testFun()

baselines = [0, -200, 10000];

for iB = 1 : length(baselines)
    infoCrit  = [1, 1, 1, NaN, 1, 1; 2, 2, 2, NaN, 2, 2; 0, 0, 100, NaN, 100, 0] ...
        + baselines(iB);
    [ResultsTable, baselinedCrit] = mT_analyseInfoCriterion(infoCrit);
    
    assert(ResultsTable.meanInfoCrit(1)==0)
    assert(ResultsTable.meanInfoCrit(2)==1)
    
    assert(ResultsTable.errorAbove(2)==0)
    assert(ResultsTable.errorBelow(2)==0)
    
    assert(ResultsTable.errorAbove(3)>0)
    assert(ResultsTable.errorBelow(3)>0)
    assert(ResultsTable.errorBelow(3)<ResultsTable.errorAbove(3))
    
    assert(ResultsTable.numBestFit(1)==2)
    assert(ResultsTable.numBestFit(2)==0)
    assert(ResultsTable.numBestFit(3)==3)
    
    assert(isequaln(baselinedCrit, infoCrit-(1+baselines(iB))));
end

disp('mT_analyseInfoCriterion passed 1 test')
    
end


