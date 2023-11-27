function subplotIdx = mT_createSubplotIdxArray(subplotWidth, subplotHeight)
% Matlab uses a particualar numbering system for subplots. Find an array
% that converts from matrix index to matlab subplot number.

subplotIdx = NaN(subplotWidth, subplotHeight);
subplotIdx(:) = 1 : length(subplotIdx(:));
subplotIdx = subplotIdx';