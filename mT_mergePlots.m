function finalFig = mT_mergePlots(inFigs, mergeMode, varargin)
% Copy all the data from a series of plots into a single figure. All
% original figures will be closed.

% INPUT
% inFigs: Vector of figure handles
% mergeMode: str. Options are:
%   "grid" for a grid of all the plots, one after another. Axis limits 
%       may be changed.
%   "spotlight" makes the first figure large and then puts the next three
%       figures smaller, above this. inFigs must be 4 figures long. If
%       the input figures have more than a single axis, then this operation
%       will be repeated for each axis. All figures must have the same
%       number of axes. The legend from the the first figure
%       is copied without checking if this legend applies to any of the 
%       other plots. If varargin{1} is true, some extraneous labels 
%       and tick labels will be removed from the plots. Y-axis limits may
%       (or may not) be changed on the three smaller figures to include 
%       all data.
% varargin{1}: bool. Default true. If true, check all input figures have 
%   the same number of axes and that, the i'th axis across all figures
%   has the same xlabel, ylabel, and ticks (for all i).
% varargin{2}: cell array. Vector as long as inFigs. Each element is used
%   as a label for the subplots that originate from the corresponding
%   figure.

% OUTPUT
% finalFig: Figure handle for the combined figure

% HISTORY
% Reviewed 17.01.2024

fontSize = 10;

if (~isempty(varargin)) && (~isempty(varargin{1}))
    checkEquiv = varargin{1};
else
    checkEquiv = true;
end

if (length(varargin) >1) && (~isempty(varargin{2}))
    figLabels = varargin{2};
else
    figLabels = {};
end

if checkEquiv
    checkEquivalence(inFigs);
end

finalFig = figure;

if strcmp(mergeMode, 'grid')
    tilePlt = tiledlayout(finalFig, 'flow');
    
    plotCount = 1;
    for iF = 1 : length(inFigs)
        allAx = findall(inFigs(iF), 'type', 'axes');
        for iAx = 1 : length(allAx)
            allAx(iAx).Parent = tilePlt;
            allAx(iAx).Layout.Tile = plotCount;
            plotCount = plotCount +1;
            axis(allAx(iAx), 'auto xy')
        end
    end
    
elseif strcmp(mergeMode, 'spotlight')
    assert(length(inFigs), 4)
    numAxes = findNumAxes(inFigs);
    
    scaler = 4;
    widthPerAx = 3*scaler;
    heightPerAx = 4;
    
    tilePlt = tiledlayout(finalFig, heightPerAx, widthPerAx*numAxes);
    axesToConsiderLimitChange = [];
    
    for iAx = 1 : numAxes
        for iF = 1 : length(inFigs)
            allAx = findall(inFigs(iF), 'type', 'axes');
            thisLegend = findobj(inFigs(iF), 'Type', 'Legend');
            if length(thisLegend) ~= 1
                error(['Must be one (and no more than one) legend ', ...
                    'in each input figure'])
            end

            % For some reason the axes seem to be ordered in the opposite
            % direction to what I would expect
            origIAx = numAxes - iAx + 1;
            thisAx = allAx(origIAx);
            
            if iF > 1
                axesToConsiderLimitChange(end+1) = thisAx;
            end
            
            if (iF == 1) && (iAx == numAxes)
                % Also want the legend
                copiedLegAx = copyobj([thisLegend, thisAx], tilePlt);
                thisAx = copiedLegAx(2);
            elseif iF == 1
                % Copy in the same way as for the above case to ensure
                % resulting fonts are consistent
                thisAx = copyobj(thisAx, tilePlt);
            else
                % Can do things simpler...
                thisAx.Parent = tilePlt;
            end
            
            if iF == 1
                numTilesInFirstRow = widthPerAx*numAxes;
                
                thisAx.Layout.Tile = 1 + ((iAx-1) * widthPerAx) + ...
                    numTilesInFirstRow;
                thisAx.Layout.TileSpan = [heightPerAx-1, widthPerAx];
            else
                numPreviousTiles = widthPerAx * (iAx - 1);
                
                thisAx.Layout.Tile = numPreviousTiles ...
                    + ((iF - 2) * scaler) ...
                    + 1;
                thisAx.Layout.TileSpan = [1, scaler];
            end
            
            % Remove some labels?
            if checkEquiv
                if iF > 1
                    xlabel(thisAx, '')
                    ylabel(thisAx, '')
                end
                
                if iF == 2
                   thisAx.XTickLabels = ...
                       retainOnlyEndElements(thisAx.XTickLabels);
                   thisAx.YTickLabels = ...
                       retainOnlyEndElements(thisAx.YTickLabels);

                elseif iF > 2
                    thisAx.XTickLabels = ...
                        cell(length(thisAx.XTickLabels), 1);
                    thisAx.YTickLabels = ...
                        cell(length(thisAx.YTickLabels), 1);
                end
                
                if iAx > 1
                    thisAx.YTickLabels = ...
                        cell(length(thisAx.YTickLabels), 1);
                end 
            end
            
            % Labeling of the subplots
            if (iF == 2) && (numAxes > 1) % At the top left of a set 
                % of plots
                plotLable = text(thisAx, ...
                    0,1.2, ...
                    ['{\bf ' char(64 + iAx) ' }'], ...
                    'Units', 'Normalized', ...
                    'VerticalAlignment', 'Bottom', ...
                    'HorizontalAlignment', 'left');
                plotLable.FontSize = fontSize;
            end
            
            if ~isempty(figLabels)
                plotLable = text(thisAx, ...
                    1, 1, ...
                    figLabels{iF}, ...
                    'Units', 'Normalized', ...
                    'VerticalAlignment', 'Top', ...
                    'HorizontalAlignment', 'right');
                plotLable.FontSize = fontSize;
            end
        end
    end
    
    % A bit complicated becuase the axes first become out of sync, then 
    % we have to sync them back up, and we also don't want the limits to
    % be any smaller than when we started
    if checkEquiv
        yLimitsOrig = ylim(axesToConsiderLimitChange(1));
        axis(axesToConsiderLimitChange, 'auto y')
        linkaxes(axesToConsiderLimitChange, 'y')
        yLimits = ylim(axesToConsiderLimitChange(1));
        
        if yLimitsOrig(1) < yLimits(1); yLimits(1) = yLimitsOrig(1); end
        if yLimitsOrig(2) > yLimits(2); yLimits(2) = yLimitsOrig(2); end
        
        for iAxForCh = 1 : length(axesToConsiderLimitChange)
            ylim(axesToConsiderLimitChange(iAxForCh), yLimits)
        end
    end
else
    error('Incorrect use of inputs')
end

for iF = 1 : length(inFigs)
    close(inFigs(iF))
end

end

function numAxes = findNumAxes(inFigs)
% Check all figures have the same number of axes and find this number

% INPUT
% inFigs: Vector of figure handles

numAxes = nan(length(inFigs), 1);

for iF = 1 : length(inFigs)
    allAx = findall(inFigs(iF), 'type', 'axes');
    numAxes(iF) = length(allAx(:));
end

numAxes = unique(numAxes);

if length(numAxes) ~= 1
    error('All input figures must have the same number of axes')
end
    
end

function checkEquivalence(inFigs)

if length(inFigs) == 1
   warning(['Only one figure provided to merge function. Therefore, ', ...
       'can not check equivalence accross figures.'])
   return
end

numAxes = findNumAxes(inFigs);
for iAx = 1 : numAxes
    
    allAx = findall(inFigs(1), 'type', 'axes');
    firstFigAx = allAx(iAx);
    
    for iF = 2 : length(inFigs)
        allAx = findall(inFigs(iF), 'type', 'axes');
        thisAx = allAx(iAx);
        
        assert(isequal(firstFigAx.XLabel.String, thisAx.XLabel.String))
        assert(isequal(firstFigAx.XLim, thisAx.XLim))
        assert(isequal(firstFigAx.XTick, thisAx.XTick))
        assert(isequal(firstFigAx.XTickLabel, thisAx.XTickLabel))
        
        assert(isequal(firstFigAx.YLabel.String, thisAx.YLabel.String))
        assert(isequal(firstFigAx.YLim, thisAx.YLim))
        assert(isequal(firstFigAx.YTick, thisAx.YTick))
        assert(isequal(firstFigAx.YTickLabel, thisAx.YTickLabel))
    end
end

% Also compare y-ticks accross the different axes within the first figure
allAx = findall(inFigs(1), 'type', 'axes');

if length(allAx) == 1
    % pass
else
    firstAx = allAx(1);
    
    for iAx = 2 : length(allAx)
        thisAx = allAx(iAx);
        
        assert(isequal(firstAx.YLim, thisAx.YLim))
        assert(isequal(firstAx.YTick, thisAx.YTick))
        assert(isequal(firstAx.YTickLabel, thisAx.YTickLabel))
    end
end

end

function cellOut = retainOnlyEndElements(cellVector)
% For a cell array with the shape of a vector, return another cell array of
% the same shape but that is empty, except for the non-empty entries in the 
% input array nearest the start and end of the vector.

nonZero = cellfun(@(el)~isEmptyOrEmptyStr(el), cellVector);
nonZero = find(nonZero);

cellOut = cell(size(cellVector));
cellOut(nonZero(1)) = cellVector(nonZero(1));
cellOut(nonZero(end)) = cellVector(nonZero(end));

end

function result = isEmptyOrEmptyStr(el)

if isempty(el) || strcmp('', el) || strcmp(' ', el)
    result = true;
else
    result = false;
end
end





