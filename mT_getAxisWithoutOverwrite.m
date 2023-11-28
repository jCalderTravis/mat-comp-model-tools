function subplotObj = mT_getAxisWithoutOverwrite(figHandle, ...
    subplotHeight, subplotWidth, thisSubplot)
% Get a subplot axis, or the only axis, without deleting the existing
% plot, ready to add more to the plot.

% INPUT
% figHandle: The figure handle we are interested in. Corresponding figure
%   will be made into the main figure.
% subplotHeight: scalar. The number of subplot rows.
% subplotWidth: scalar. The number of subplot columns.
% thisSubplot: scalar. The linear index of the subplot we want to plot 
%   onto.

% OUTPUT
% subplotObj: Handle to the subplot that we want to use.

set(0, 'currentFigure', figHandle)

if (subplotHeight == 1) && (subplotWidth == 1)
    assert(thisSubplot == 1)
    subplotObj = gca;
else
    subplotObj = subplot(subplotHeight, subplotWidth, thisSubplot);
end

hold on