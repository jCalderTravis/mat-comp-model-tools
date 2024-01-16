function mT_lineToSides(xVals, yVals, iPos, colourIncFade, lineWidth)
% Plot a line from a specific point, halfway to the previous and next
% points. For the first and final points, only lines halfway to the next
% and previous points, respectively, are drawn.

% xVals: vector of float. The x-values of the points.
% yVals: vector of float | scalar. The y-values of the points. If scalar,
%   the same yValue is aways used.
% iPos: int. The index of the point in xVals and yVals from which the lines
%   to the previous and next point should originate.
% colourIncFade: 3- or 4-length vector describing the colour to plot in.
%   (Length 4 to also plot with a specific fade level.)
% lineWidth: scalar. Width of the plotted line.

% HISTORY
% Reviewed 16.01.2024

numPoints = length(xVals);
if length(yVals) == 1
    yVals = repmat(yVals, numPoints, 1);
end
assert(length(yVals) == numPoints)
assert(all(diff(xVals(:))>=0))
assert((size(xVals, 2) == 1) || (size(xVals, 1) == 1))
assert(size(yVals, 2) == 1)

currentX = xVals(iPos);
currentY = yVals(iPos);

% Start with the lines to the right of the point. There
% is nothing to draw to the right if this is the final
% data point.
if iPos < numPoints
    nextX = xVals(iPos +1);
    nextY = yVals(iPos +1);
    
    plot([currentX, (currentX + nextX)/2], ...
        [currentY, (currentY + nextY)/2], ...
        'Color', colourIncFade, ...
        'LineWidth', lineWidth);
end

% Now the lines to the left of the point. There
% is nothing to draw to the right if this is the first
% data point.
if iPos > 1
    prevX = xVals(iPos -1);
    prevY = yVals(iPos -1); 
    
    plot([(prevX + currentX)/2, currentX], ...
        [(prevY + currentY)/2, currentY], ...
        'Color', colourIncFade, ...
        'LineWidth', lineWidth);
end

