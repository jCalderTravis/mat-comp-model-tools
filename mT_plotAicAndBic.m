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
%                       instead of simply numebering the models

% OUTPUT
% CritMeans             Stucture with field for AIC and BIC containing vector of
%                       information criterion means, one for each model
% figH                  Figure handle

if ~isempty(varargin)
    modelNames = varargin{1};
else
    modelNames = [];
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

for iCrit = 1 : length(infoCrit)
    
    [CritResultsTable, baselinedCrit] = mT_analyseInfoCriterion(infoCrit{iCrit});
    CritMeans.(critNames{iCrit}) = CritResultsTable.meanInfoCrit;
    
    % Plot type A: aggregate scores
    subPlotObj = subplot(critCounter-1, 2, 1 + ((iCrit -1) *2) );
    subPlotObj.LineWidth = axisLineWidth;
    subPlotObj.FontSize = fontSize;
    
    xticks(CritResultsTable.modelNums)
    ylabel({['Mean ' nameForPlot{iCrit}], '(difference from best model)'})
    xlabel('Model number')
    
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
    
    % Replace model numbers with names
    if ~isempty(modelNames)
        if length(xticklabels()) ~= length(modelNames)
            error('Number of labels does not match the number of ticks')
        end
        xticklabels(modelNames)
        xtickangle(90)
    end
    
    
    % Plot type B: num participants best described
    subPlotObj = subplot(critCounter-1, 2, 2 + ((iCrit -1) *2) );
    subPlotObj.LineWidth = axisLineWidth;
    subPlotObj.FontSize = fontSize;
    subPlotObj.XAxisLocation = 'origin';
    
    if length(infoCrit) > 1
        ylabel({'Number best fitting participants', ['(' nameForPlot{iCrit} ')']})
    else
        ylabel('Number best fitting participants')
    end
    
    xlabel('Model number')
    xticks(CritResultsTable.modelNums)
    
    hold on
    
    barObj = bar(CritResultsTable.modelNums, CritResultsTable.numBestFit);
    
    barObj.FaceColor = 'none';
    barObj.EdgeColor = [0, 0, 0];
    barObj.LineWidth = plotLineWidth;
    
    % Add line at y=0
    refL = refline(0, 0);
    refL.Color = [0, 0, 0];
    refL.LineWidth = axisLineWidth;
    
    set(gca, 'TickDir', tickDirection);
    xlim([0.1, length(CritResultsTable{:, 1}) + 0.9])
    
    % Replace model numbers with names
    if ~isempty(modelNames)
        if length(xticklabels()) ~= length(modelNames)
            error('Number of labels does not match the numebr of ticks')
        end
        xticklabels(modelNames)
        xtickangle(90)
    end
    
end
    

