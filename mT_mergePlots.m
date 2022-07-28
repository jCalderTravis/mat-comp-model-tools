function finalFig = mT_mergePlots(inFigs, mergeMode)
% Copy all the data from a series of plots into a single figure. All
% original figures will be closed.

% INPUT
% inFigs: Vector of figure handles
% mergeMode: str. Options are:
%   "grid" for a grid of all the plots, one after another. Axis limits 
%       may be changed.
%   "spotlight" makes the first figure large and then puts the next three
%       figures smaller, underneath this. inFigs must be 4 figures long. If
%       the input figures have more than a single axis, then this operation
%       will be repeated for each axis. All figures must have the same
%       number of axes. Removes all x- and y- labels except for the
%       highlighted plot

% OUTPUT
% finalFig: Figure handle for the combined figure

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
    
    tilePlt = tiledlayout(finalFig, 4, widthPerAx*numAxes);
    
    for iAx = 1 : numAxes
        for iF = 1 : length(inFigs)
            allAx = findall(inFigs(iF), 'type', 'axes');

            % For some reason the axes seem to be ordered in the opposite
            % direction to what I would expect
            origIAx = numAxes - iAx + 1;
            thisAx = allAx(origIAx);
            
            thisAx.Parent = tilePlt;
            
            if iF == 1
                thisAx.Layout.Tile = 1 + ((iAx-1) * widthPerAx);
                thisAx.Layout.TileSpan = [heightPerAx-1, widthPerAx];
            else
                numPreviousTiles = (heightPerAx-1)*(widthPerAx*numAxes);
                numPreviousTiles = numPreviousTiles + ...
                    (widthPerAx * (iAx - 1));
                
                thisAx.Layout.Tile = numPreviousTiles + iF - 1;
                thisAx.Layout.TileSpan = [1, 1];
            end
            
            % Remove x- or y-labels?
            if iF ~= 1
                xlabel(thisAx, '')
                ylabel(thisAx, '')
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






