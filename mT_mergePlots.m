function finalFig = mT_mergePlots(inFigs)
% Copy all the data from a series of plots into a single figure. All
% original figures will be closed. Axis limits may be changed.

% INPUT
% inFigs: Vector of figure handles

% OUTPUT
% finalFig: Figure handle for the combined figure

finalFig = figure;
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

for iF = 1 : length(inFigs)
    close(inFigs(iF))
end