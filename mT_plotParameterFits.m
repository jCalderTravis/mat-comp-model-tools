function mT_plotParameterFits(DSet, modelNumber, plotType, sepPlots, smallFont)
% Plots the distribution accross participants of all parameters in modelNumber
% model. Only the best fit attained for each participant is used. If the data
% were simulated and a true value for the parameter exists a reference line is
% added. See the README for how to pass this information, under 
% 'DSet.P(i).Sim'.

% INPUT
% plotType: 'hist', histogram of fitted params around a reference line which is the 
% mean simulated param value across participants, or 'scatter', scatter plot of
% fitted param vs, simulated param
% sepPlots: Some 'parameters' are actually arrays of parameters. Columns of
% these arrays are always plotted seperately. If there is only one column, all 
% data is plotted on one figure, unless sepPlots is set to true. If there is
% more than one column sepPlots does nothing.
% smallFont: (optional) Display in small font if true

if (nargin > 4) && smallFont
    fontSize = 4;
else
    fontSize = 10;
end

figure

fittedParams = fieldnames(DSet.P(1).Models(modelNumber).BestFit.Params);

% Check the fitted params are the same for all participants.
for iPtpnt = 2 : length(DSet.P)    
    if ~isequal(fieldnames(DSet.P(iPtpnt).Models(modelNumber).BestFit.Params), ...
            fittedParams)
        error('All participant data should have the same parameters fitted')
    end
end

% If the data were simulated, find the simulation parameters. Which simulation
% parameters we need depends on what we will be ploting later.
if isfield(DSet.P(1), 'Sim') && isfield(DSet.P(1).Sim, 'Params')
    if strcmp(plotType, 'hist')
        knownSimVals = true;
        SimParamVals = mT_retrieveSimParams(DSet, 'average');
        
    elseif strcmp(plotType, 'scatter')
        SimParamVals = mT_retrieveSimParams(DSet, 'stack');
    end
else
    knownSimVals = false;
    
    if strcmp(plotType, 'scatter')
        error('This plot type requires simulated parameter values.')
    end
end


% If we are doing a scatter plot only plot params for which we know the
% simulation values
if strcmp(plotType, 'scatter')
    originParams = fittedParams;
    simParams = fieldnames(SimParamVals);
    fittedParams = intersect(fittedParams, simParams);
    
    if (length(originParams) ~= length(fittedParams)) ...
            || (length(simParams) ~= length(fittedParams))
        warning('params ignored')
    end
end


for iPlot = 1 : length(fittedParams)    
    % Some 'parameters' are actually arrays of parameters. Find the details.
    nCols = size(DSet.P(1).Models(...
        modelNumber).BestFit.Params.(fittedParams{iPlot}), 2);
    nVals = size(DSet.P(1).Models(...
        modelNumber).BestFit.Params.(fittedParams{iPlot}), 1);
    
    if (nCols == 1) && sepPlots
        individualPlots = true;
        nRowPlots = nVals; 
    else
        individualPlots = false;
        nRowPlots = nCols;
    end
    
    allXLims = NaN(nRowPlots, 2);
    allYLims = NaN(nRowPlots, 2);
    
    for iRowPlot = 1 : nRowPlots
        subplot(length(fittedParams), nRowPlots, ((iPlot-1)*nRowPlots) + iRowPlot)
        hold on
        
        set(gca, 'FontSize', fontSize)
        
        % Loop over the values in the column, plotting them on the same
        % subplot, if requested.
        if ~individualPlots
            valColour = cell(nVals, 1);
            refVal = cell(nVals, 1);
            
            for iVal = 1 : nVals
                valColour{iVal} = mT_pickColour(iVal);
                
                fittedParamVals = mT_stackData(DSet.P, ...
                        @(str)str.Models(modelNumber).BestFit.Params.(...
                        fittedParams{iPlot})(iVal, iRowPlot));
                
                if strcmp(plotType, 'hist')    
                    histogram(fittedParamVals, 20, 'facealpha', .5, ...
                        'edgecolor', 'none', 'facecolor', valColour{iVal}, ...
                        'Normalization', 'countdensity');
                    
                    % Add reference line to indicate the true parameter value.
                    % Note we have to check if the fitted parameter was actually
                    % specified in the stimulation (the simulation and analysis may
                    % used different Models).
                    refVal{iVal} = NaN;
                    if knownSimVals && isfield(SimParamVals, fittedParams{iPlot})
                        refVal{iVal} = ...
                            SimParamVals.(fittedParams{iPlot})(iVal, iRowPlot);
                    end
                    
                elseif strcmp(plotType, 'scatter')
                    
                    % Which dimention pariticpant data will be stored along
                    % depends on how many columns the param struct field has.
                    if nRowPlots == 1
                        simulatedParams ...
                            = SimParamVals.(fittedParams{iPlot})(iVal, :);
                        assert(length(simulatedParams) == length(DSet.P))
                    else
                        simulatedParams ...
                            = SimParamVals.(fittedParams{iPlot})(iVal, iRowPlot, :);
                        assert(length(simulatedParams) == length(DSet.P))
                    end
                    
                    scatter(simulatedParams, fittedParamVals, ...
                        'MarkerEdgeColor', valColour{iVal});
                    
                    % We do not want a reference line for a scatter plot
                    refVal = []; 
                end
            end
            
        elseif individualPlots
            valColour = {mT_pickColour(iRowPlot)};
            
            fittedParamVals = mT_stackData(DSet.P, ...
                @(str)str.Models(modelNumber).BestFit.Params.(...
                fittedParams{iPlot})(iRowPlot, 1));
            
            if strcmp(plotType, 'hist')
                histogram(fittedParamVals, 20, 'facealpha', .5, ...
                    'edgecolor', 'none', 'facecolor', valColour{1}, ...
                    'Normalization', 'countdensity');
                
                % Add reference line to indicate the true parameter value.
                % Note we have to check if the fitted parameter was actually
                % specified in the stimulation (the simulation and analysis may
                % used different Models).
                refVal = {NaN};
                if knownSimVals && isfield(SimParamVals, fittedParams{iPlot})
                    refVal = {SimParamVals.(fittedParams{iPlot})(iRowPlot, 1)};
                end
                
            elseif strcmp(plotType, 'scatter')
                % How the fitted params for all participants are stacked depends
                % on the number of dimention of the original param array. To be
                % here in the code it must be the case that individual plots is
                % true, and so it must be the case that the original param
                % array was a column vector, therefore the data for all
                % participants will be stacked along the second dimention.
                assert(length(size(SimParamVals.(fittedParams{iPlot}))) == 2)
                simulatedParams ...
                        = SimParamVals.(fittedParams{iPlot})(iRowPlot, :);
                assert(length(simulatedParams) == length(DSet.P))
                    
                scatter(simulatedParams, fittedParamVals, ...
                    'MarkerEdgeColor', valColour{1});
                
                refVal = []; % We do not want a reference line for a scatter plot
            end
            
            [allXLims, allYLims] = finishPlot(individualPlots, ...
                fittedParams, refVal, valColour, ...
                allXLims, allYLims, 1, iPlot, nRowPlots, iRowPlot, fontSize);
        end
        
        % Plot the reference lines. (Done in a seperate loop so that they
        % are all the same length, if there is more than one histogram per
        % plot.)
        if ~individualPlots
            for iVal = 1 : nVals
                [allXLims, allYLims] = finishPlot(individualPlots, ...
                    fittedParams, refVal, valColour, ...
                    allXLims, allYLims, iVal, iPlot, nRowPlots, ...
                    iRowPlot, fontSize);
            end
        end
        
    end
    
    % For subplots of the same parameter set to have the same x and y lims
    sharedXLims(1) = min(allXLims(:, 1));
    sharedXLims(2) = max(allXLims(:, 2));
    sharedYLims(1) = min(allYLims(:, 1));
    sharedYLims(2) = max(allYLims(:, 2));
    
    for iRowSubPlot = 1 : nRowPlots
        subplot(length(fittedParams), nRowPlots, ...
            ((iPlot-1)*nRowPlots) + iRowSubPlot)
        xlim(sharedXLims)
        ylim(sharedYLims)
    end
    
    % For scatter plots, plot a line through y=x
    if strcmp(plotType, 'scatter')
        for iRowSubPlot = 1 : nRowPlots
            subplot(length(fittedParams), nRowPlots, ...
                ((iPlot-1)*nRowPlots) + iRowSubPlot)
            
            xLimits = xlim;
            yLimits = ylim;
            endPoint = min([xLimits(2), yLimits(2)]);
            
            line([0, endPoint], [0, endPoint], ...
                'LineWidth', 0.5, 'Color', [0, 0, 0]);
        end
    end
end

end


function [allXLims, allYLims] = finishPlot(individualPlots, fittedParams, ...
    refVal, valColour, allXLims, allYLims, iVal, iPlot, ...
    nRowPlots, iRowSubPlot, fontSize)
% Finish the current figure by adding a reference line, and recording the axis
% limits.

% INPUT
% Definied as in main script apart from...
% iPlot: The plot number in the current row, counting from left to right.

if ~isempty(refVal)
    line([refVal{iVal}, refVal{iVal}], ylim, ...
        'LineWidth', 2, 'Color', valColour{iVal});
end

allXLims(iRowSubPlot, :) = xlim;
allYLims(iRowSubPlot, :) = ylim;

% Add title
if (~individualPlots) && (nRowPlots == 1)
    title(fittedParams{iPlot} , 'FontSize', fontSize)
elseif ~individualPlots
    title([fittedParams{iPlot} ', set ' num2str(iRowSubPlot)], ...
        'FontSize', fontSize)
elseif individualPlots && iRowSubPlot == 1
    title(fittedParams{iPlot} , 'FontSize', fontSize)
end

end

