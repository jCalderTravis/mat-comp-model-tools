function mT_addLegend(figHandle, legendLabels, legendColours, title, ...
    fontSize, lineWidth)
% Add a legend to a plot/subplot by drawing new invisible lines.

% INPUT
% figHandle: Figure to add legend to
% legendLabels: cell array of str. Gives the labels of the series to add 
%   to the legend.
% legendColours: cell array of 3-element vectors. Gives the colours for the
%   series described in legendLabels.
% title: empty or str. Provide legend title, if desired.
% fontSize: scalar. Font size for legend. May be empty to use default.
% lineWidth: scalar. Line width for legend. May be empty to use default.

assert(length(legendLabels) == length(legendColours))

if ~exist('fontSize', 'var')
    fontSize = 10;
end

if ~exist('lineWidth', 'var')
    lineWidth = 1;
end

% Find shape of subplots
subplotWidth = findNumSubplots(figHandle, 1);
subplotHeight = findNumSubplots(figHandle, 2);
subplotIdx = mT_createSubplotIdxArray(subplotWidth, subplotHeight);

set(0, 'currentFigure', figHandle)
subplotNum = subplotIdx(ceil(subplotHeight/2), end);
mT_getAxisWithoutOverwrite(figHandle, subplotHeight, subplotWidth, ...
    subplotNum);

hold on

for iLabel = 1 : length(legendLabels)
    legendLine(iLabel) = ...
        errorbar(NaN, NaN, NaN, NaN, 'Color', legendColours{iLabel});
end

legObj = legend(legendLine, legendLabels{:});
legend boxoff

legObj.FontSize = fontSize;
legObj.LineWidth = lineWidth;
legObj.ItemTokenSize(1) = 15;
legObj.Location = 'southeast';

if exist('title', 'var') && ~isempty(title)
    title(legObj, title)
end

end


function numSubplots = findNumSubplots(figHandle, axis)

positions = [];
currentAxes = findobj(get(figHandle, 'Children'), 'type', 'axes', ...
    '-depth', 1);
for iC = 1 : length(currentAxes)
    positions = [positions, currentAxes(iC).Position(axis)];
end

numSubplots = length(unique(positions));

end



