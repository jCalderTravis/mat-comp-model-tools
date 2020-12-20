function colour = mT_pickColour(colourNum)
% Returns 3-element vector specifying a colour. Each input colourNum, provides a
% different output colour.

colours = NaN(7, 3);

% Colours taken from Okabe & Ito, Color Universal Design, 2008
% (https://jfly.uni-koeln.de/color/index.html)
colours(1, :) = [0, 0, 0]; % Black
colours(2, :) = [0.9, 0.6, 0]; % Orange
colours(3, :) = [0.35, 0.7, 0.9]; % Sky blue
colours(4, :) = [0, 0.6, 0.5]; % Bluish green
colours(5, :) = [0, 0.45, 0.7]; % Blue
colours(6, :) = [0.8, 0.4, 0]; % Vermillion
colours(7, :) = [0.8, 0.6, 0.7]; % Reddish purple

% Pick!
colourNum = mod(colourNum, 7);
colourNum(colourNum == 0) = 7;
colour = colours(colourNum, :);