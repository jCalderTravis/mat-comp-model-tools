function [CritMeans, figH] = mT_plotAicAndBic(aicData, bicData, predDencity, ...
    figureTitle, individualVals, varargin)
% Makes plots of the agregate AIC, BIC, and/or predDecity, along with the number of
% participants best fit by each model. 

% INPUT
% aicData and bicData   Should be [numModels x numParticipants] arrays, may be
%                       left empty
% predDecity            [numModels x numParticipants] array of the *negative*
%                       average cross validated log-likelihood. May be left empty
% title                 Figure title
% individualVals        If true then on top of the bar plot of mean AIC/BIC,
%                       also plots the participant by participant values as line
%                       plots.
% varargin{1}           numModels long cell array of model names to use 
%                       instead of simply numebering the models. If
%                       supplied, only the bottom row of subplots will have
%                       x-tick labels.
% varargin{2}           scalar. If provided the y-limits on the plots of
%                       information criteria means will be extended
%                       by this quantity at the lower y-limit. Default 0.
% varargin{3}           bool. If True (default) letter the subplots.
% varargin{4}           bool. If True (default) also plot the number of 
%                       participants best fit by each model, not just the 
%                       information criteria averages.

% OUTPUT
% CritMeans             Stucture with field for AIC and BIC containing vector of
%                       information criterion means, one for each model
% figH                  Figure handle

% HISTORY
% Reviewed 2020

if ~isempty(varargin)
    modelNames = varargin{1};
    xlabelTxt = [];
else
    modelNames = [];
    xlabelTxt = 'Model number';
end

if (length(varargin) >= 2) && (~isempty(varargin{2}))
    expandY = varargin{2};
else
    expandY = 0;
end

if (length(varargin) >= 3) && (~isempty(varargin{3}))
    lettering = varargin{3};
else
    lettering = true;
end

if (length(varargin) >= 4) && (~isempty(varargin{4}))
    plotNumPtpnts = varargin{4};
else
    plotNumPtpnts = true;
end

assert(~isempty(individualVals))
if any(predDencity(:)<0); error('Pass the **negative** cross validated LL.'); end

figH = figure('Name', figureTitle, 'NumberTitle', 'off');

plotLineWidth = 1;
axisLineWidth = 1;
inidividualLineWidth = 1;
fontSize = 10;
tickDirection = 'out';

% Store data in a format we can loop over
critCounter = 1;
critNames = {};
nameForPlot = {};

if ~isempty(aicData)
    infoCrit{critCounter} = aicData;
    critNames{critCounter} = 'AIC';
    nameForPlot{critCounter} = 'AIC';
    critCounter = critCounter +1;
end

if ~isempty(bicData)
    infoCrit{critCounter} = bicData;
    critNames{critCounter} = 'BIC';
    nameForPlot{critCounter} = 'BIC';
    critCounter = critCounter +1;
end

if ~isempty(predDencity)
    infoCrit{critCounter} = predDencity;
    critNames{critCounter} = 'Negative_LL';
    nameForPlot{critCounter} = [char(8211), 'LLcv'];
    critCounter = critCounter +1;
end

if lettering
    pltCount = 1;
end

if plotNumPtpnts
    width = 2;
else
    width = 1;
end
tiledlayout(critCounter-1, width, TileSpacing="compact")

for iCrit = 1 : length(infoCrit)
    
    [CritResultsTable, baselinedCrit] = mT_analyseInfoCriterion(infoCrit{iCrit});
    CritMeans.(critNames{iCrit}) = CritResultsTable.meanInfoCrit;
    
    % Plot type A: aggregate scores
    subPlotObj = nexttile(1 + ((iCrit -1) * width));
    subPlotObj.LineWidth = axisLineWidth;
    subPlotObj.FontSize = fontSize;
    
    xticks(CritResultsTable.modelNums)
    ylabel({['Mean ' nameForPlot{iCrit}], '(relative)'})
    if (iCrit == length(infoCrit)) && (~isempty(xlabelTxt))
        xlabel(xlabelTxt)
    end
    
    hold on
    
    % Add line plot of individual participant values if requested
    if individualVals
        for iPtpnt = 1 : size(infoCrit{iCrit}, 2)
            plot(1:size(infoCrit{iCrit}, 1), baselinedCrit(:, iPtpnt), ...
                'Color', [0.7, 0.7, 0.7], 'LineWidth', inidividualLineWidth)
        end
    end
    
    % Now plot main results
    barObj = bar(CritResultsTable.modelNums, CritResultsTable.meanInfoCrit); 
    barObj.FaceColor = 'none';
    barObj.EdgeColor = [0, 0, 0];
    barObj.LineWidth = plotLineWidth;
    
    % Error bars
    erObj = errorbar(CritResultsTable.modelNums, CritResultsTable.meanInfoCrit, ...
        CritResultsTable.errorBelow, CritResultsTable.errorAbove);
    
    erObj.LineStyle = 'none';
    erObj.LineWidth = plotLineWidth;
    erObj.CapSize = 10;
    errorColour = [0, 0, 0];
    erObj.Color = errorColour;
    
    % Add line at y=0
    refL = refline(0, 0);
    refL.Color = [0, 0, 0];
    refL.LineWidth = axisLineWidth;
    
    set(gca, 'TickDir', tickDirection);
    box off
    
    xlim([0.1, length(CritResultsTable{:, 1}) + 0.9])
    if expandY ~= 0
        oldYLims = ylim();
        ylim([oldYLims(1)-expandY, oldYLims(2)])
    end
    
    replaceNumbersWithNames(modelNames, iCrit == length(infoCrit))
    
    if lettering
        pltCount = addLetterForSubplot(pltCount, fontSize);
    end
    
    % Plot type B: num participants best described
    if plotNumPtpnts
        subPlotObj = nexttile(2 + ((iCrit -1) *width));
        subPlotObj.LineWidth = axisLineWidth;
        subPlotObj.FontSize = fontSize;
        subPlotObj.XAxisLocation = 'origin';

        if length(infoCrit) > 1
            ylabel({'Num. best fit', ...
                ['participants (' nameForPlot{iCrit} ')']})
        else
            ylabel('Number best fitting participants')
        end

        if (iCrit == length(infoCrit)) && (~isempty(xlabelTxt))
            xlabel(xlabelTxt)
        end
        xticks(CritResultsTable.modelNums)

        hold on

        barObj = bar(CritResultsTable.modelNums, ...
            CritResultsTable.numBestFit);

        barObj.FaceColor = 'none';
        barObj.EdgeColor = [0, 0, 0];
        barObj.LineWidth = plotLineWidth;

        % Add line at y=0
        refL = refline(0, 0);
        refL.Color = [0, 0, 0];
        refL.LineWidth = axisLineWidth;

        set(gca, 'TickDir', tickDirection);
        xlim([0.1, length(CritResultsTable{:, 1}) + 0.9])

        replaceNumbersWithNames(modelNames, iCrit == length(infoCrit))

        if lettering
            pltCount = addLetterForSubplot(pltCount, fontSize);
        end
    end
end

end

function pltCount = addLetterForSubplot(pltCount, fontSize)

plotLable = text(-0.08, 1.04, ...
    ['{\bf ' char(64 + pltCount) ' }'], ...
    'Units', 'Normalized', ...
    'VerticalAlignment', 'Bottom');
plotLable.FontSize = fontSize;
pltCount = pltCount +1;

end

function replaceNumbersWithNames(modelNames, isLowest)
% Replace model numbers with model names

% INPUT
% isLowest: bool. If true, means that we are working with the lowst row
%   of subplots. When false, and modelNames is not empty, all labeling is 
%   suppressed.

if ~isempty(modelNames)
    if length(xticklabels()) ~= length(modelNames)
        error('Number of labels does not match the numebr of ' +...
            'ticks')
    end

    if isLowest
        xticklabels(modelNames)
        xtickangle(90)
    else
        xticklabels([])
    end
end

end


    

