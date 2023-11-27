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

if isempty(fontSize)
    fontSize = 10;
end

if isempty(lineWidth)
    lineWidth = 1;
end

% Find shape of subplots
findSubplotSize = @(i) length([figHandle.Children(:).Position(i)]);
subplotWidth = findSubplotSize(1);
subplotHeight = findSubplotSize(2);
subplotIdx = mT_createSubplotIdxArray(subplotWidth, subplotHeight);

set(0, 'currentFigure', figHandle)
subplotNum = subplotIdx(ceil(subplotHeight/2), end);
subplot(subplotHeight, subplotWidth, subplotNum);
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

if ~isempty(title)
    title(legObj, title)
end