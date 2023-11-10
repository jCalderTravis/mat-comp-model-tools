function mT_addLegend(figHandle, subplotHeight, subplotWidth, subplotNum, ...
    legendLabels, legendColours, title, fontSize, lineWidth)
% Add a legend to a plot/subplot but drawing new invisible lines.

% INPUT
% figHandle: Figure to add legend to
% subplotHeight: scalar. Number of subplots vertically. 1 if only single
%   plot.
% subplotWidth: scalar. Number of subplots horizontally.
% subplotNum: scalar. The index of the subplot to plot onto.
% legendLabels: cell array of str. Gives the labels of the series to add 
%   to the legend.
% legendColours: cell array of 3-element vectors. Gives the colours for the
%   series described in legendLabels.
% title: empty or str. Provide legend title, if desired.
% fontSize: scalar. Font size for legend
% lineWidth: scalar. Line width for legend

assert(length(legendLabels) == length(legendColours))

set(0, 'currentFigure', figHandle)
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