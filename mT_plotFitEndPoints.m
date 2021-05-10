function [numSuccess, restartsFigure, numSuccessFig] = mT_plotFitEndPoints(DSet, ...
    individualPlots, tol, varargin)
% Plot the final LL produced from all the start points for all the models, on a
% seperate figure for each participant and/or find the sucess rate of fits, where
% a success is ending within tol LLs of the best fit. Plot this as participant by 
% model heat map.

% INPUT
% individualPlots: If true, a plot for each participant is produced with more
% detail
% tol: How many LLs away from the best fit will we count as sucesses?
% varargin{1}: A participant number if just want to plot one participant, or row
% vector of particpant numbers.
% varargin{2}: numModels long cell array of model names to use instead of 
% simply numebering the models

if (~isempty(varargin)) && (~isempty(varargin{1}))
    toPlot = varargin{1};
    plotAll = false;
    disp('Not plotting data from all participant, as requested.')
else
    toPlot = 1 : length(DSet.P);
    plotAll = true;
end

if (length(varargin)>1) && (~isempty(varargin{2}))
    modelNames = varargin{2};
else
    modelNames = [];
end

% Check same models have been applied to all participants and in same order
mT_findAppliedModels(DSet);

numPtpnts = length(toPlot);
numModels = length(DSet.P(1).Models);
numSuccess = NaN(numPtpnts, numModels);
numFits = NaN(numPtpnts, numModels);
successRate = NaN(numPtpnts, numModels);
restartsRequired = NaN(numPtpnts, numModels);


for iPlot = 1 : length(toPlot)
    iP = toPlot(iPlot);
    
    if individualPlots
        figure
        hold on
    end
    
    for iM = 1 : length(DSet.P(iP).Models)
        
        fittedLLs = mT_stackData(DSet.P(iP).Models(iM).Fits, @(struct) struct.LL);

        if individualPlots
            scatter(fittedLLs, ones(size(fittedLLs)) * iM)
        end
        
        restartsRequired(iPlot, iM) = findMinRequiredSample(fittedLLs', tol);
        
        % How many of the fits ended close to the best fit?
        baseline = max(fittedLLs);
        baselinedLLs = fittedLLs - baseline;
        
        numSuccess(iPlot, iM) = sum(baselinedLLs > -tol);
        numFits(iPlot, iM) = length(baselinedLLs);
        successRate(iPlot, iM) = numSuccess(iPlot, iM)/numFits(iPlot, iM);
        
        if any(isnan(baselinedLLs))
            error('Assume all fits reuslt in a numeric LL')
        end
    end
    
    if individualPlots
        xlabel('Final LL from start point')
        ylabel('Model number')
        ylim([0, iM+1])
    end
end

% Success rate heat map
numSuccessFig = figure;
heatmap(numSuccess, 'FontSize', 10)
colorbar('off')
xlabel('Model')
if plotAll
    ylabel('Participant')
else
    ylabel('Paricipants in order requested when calling function.')
end
title(['Fits within ', num2str(tol), ' log-likelihood of the maximum found'])

figure
heatmap(numFits)
title('numFits')

figure
heatmap(successRate)
title('Success rate')

figure
heatmap(restartsRequired)
title('Estimated number of starts required')

restartsFigure = figure;
restartsRequired(restartsRequired == Inf) = nan;
h = heatmap(restartsRequired, 'CellLabelColor', 'none');
h.GridVisible = 'off';
h.XLabel = 'Model';
if ~isempty(modelNames)
    if length(h.XData) ~= length(modelNames)
        error('Number of labels does not match the number of ticks')
    end
    h.XDisplayLabels = modelNames;
end
if plotAll
    h.YLabel = 'Participant';
else
    h.YLabel = 'Paricipants in order requested when calling function.';
end
oldLables = h.YDisplayLabels;
h.YDisplayLabels(:) = {' '};
h.YDisplayLabels(1) = oldLables(1);
h.YDisplayLabels(end) = oldLables(end);
title('Estimated number of runs required')

end


function restartsRequired = findMinRequiredSample(fittedLLs, tol)
% Perform analysis from Acerbi et al. (2018;
% https://doi.org/10.1371/journal.pcbi.1006110) supplimentary material,
% end of section 4.2

if size(fittedLLs, 2) ~= 1; error('Bug'); end
assert(~any(isnan(fittedLLs)))

globalOptBestEst = max(fittedLLs);

% For 1 to length(fittedLLs), calculate via bootstrap the
% probability of a regret smaller than tol when using that many fitting runs. 
% Regret is difference between best fit in the sample, and our best estimate 
% of max LL.
probGoodEst = NaN(length(fittedLLs), 1);

for iSampleSize = 1 : length(fittedLLs)
    nSims = 10000;
    simulatedFittedLLs = NaN(nSims, iSampleSize);
    
    % Draw a random sample
    drawIdx = randsample(length(fittedLLs), nSims * iSampleSize, true);
    simulatedFittedLLs(:) = fittedLLs(drawIdx);
    
    bestEstInSamples = max(simulatedFittedLLs, [], 2);
    assert(isequal(size(bestEstInSamples), [nSims, 1]))
    regret = globalOptBestEst - bestEstInSamples;
    assert(all(regret(:)>=0))
    
    % What is the probability of having a regret smaller than the tolerance?
    probGoodEst(iSampleSize) = mean(regret < tol);
    
end

% Are any probabilities of a good estiamtion greater than 0.99?
lim = 0.99;

if ~(any(probGoodEst > lim))
    restartsRequired = Inf;
else
    % If so, what sample size do we need for this
    successSampleSizes = probGoodEst > lim;
    successSampleSizes = find(successSampleSizes);
    restartsRequired = min(successSampleSizes);
    
    % Do all samples sizes above this achieve at least the same level of
    % success?
    if any(diff(successSampleSizes) ~= 1)
        warning('A greater sample size did not achive the same success rate')
    end
end
end
        