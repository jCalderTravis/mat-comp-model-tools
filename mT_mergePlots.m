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
%       number of axes. The legend from the final axis in the first figure
%       is copied without checking if this legend applies to any of the 
%       other plots. If varargin{1} is true, some extraneous labels 
%       and tick labels will be removed from the plots.
% varargin{1}: bool. Default true. If true, check all input figures have 
%   the same number of axes and that, the i'th axis across all figures
%   has the same xlabel, ylabel, and ticks (for all i). 

% OUTPUT
% finalFig: Figure handle for the combined figure

if (~isempty(varargin)) && (~isempty(varargin{1}))
    checkEquiv = varargin{1};
else
    checkEquiv = true;
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
    
    widthPerAx = 3;
    heightPerAx = 4;
    
    tilePlt = tiledlayout(finalFig, 4, widthPerAx*numAxes, ...
        'TileSpacing', 'compact');
    
    for iAx = 1 : numAxes
        for iF = 1 : length(inFigs)
            allAx = findall(inFigs(iF), 'type', 'axes');

            % For some reason the axes seem to be ordered in the opposite
            % direction to what I would expect
            origIAx = numAxes - iAx + 1;
            thisAx = allAx(origIAx);
            
            thisAx.Parent = tilePlt;
            
            if iF == 1
                numTilesInFirstRow = widthPerAx*numAxes;
                
                thisAx.Layout.Tile = 1 + ((iAx-1) * widthPerAx) + ...
                    numTilesInFirstRow;
                thisAx.Layout.TileSpan = [heightPerAx-1, widthPerAx];
            else
                numPreviousTiles = widthPerAx * (iAx - 1);
                
                thisAx.Layout.Tile = numPreviousTiles + iF - 1;
                thisAx.Layout.TileSpan = [1, 1];
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
                end
                
                if iF > 2
                    thisAx.XTickLabels = ...
                        cell(length(thisAx.XTickLabels), 1);
                    thisAx.YTickLabels = ...
                        cell(length(thisAx.YTickLabels), 1);
                end
            end
            
            % Legend
            if (iF == 1) && (iAx == numAxes)
                % WORKING HERE -- this not working
               leg = findobj(inFigs(iF), 'type', 'Legend');
               copyobj(leg, thisAx);
            end
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





