function figHandle = mT_plotSetsOfSeries(PlotData, PlotStyle, varargin)
% Produces subplots plots of sets of series

% INPUT
% PlotData [subplots in y-drection by subplots in x-direction] strct array,
% with fields...
%   Xvals   Either single strcutre or [num series] long strcut array with
%           fields...
%       Vals        The i-th structure should contain the x-values for the i-th
%                   series. If the Xvals strcuture is only 1 long, these these
%                   values will be used for all series.
%   Yvals   [num series] long struct array with fields...
%       Vals
%       Fade        optional
%       UpperError  Distance from Val
%       LowerError  Unsigned distance from Val
%   
% PlotStyle struct array with fields...
%   General
%         Some general formatting settings that makes the formatting better for 
%         viewing on a PC, or having in a paper... Options: 'computer', 'paper'
%   Xaxis [size(PlotData, 2)] struct array with fields...
%       Title       optional
%       Ticks       optional. First and last will be used as the limits of
%                   for the plot, unless Xaxis.Lims is set.
%       TickLabels  optional.
%       InvisibleTickLablels optional. Vector which gives indecies of
%                   TickLabels. For the labels and ticks corresponding to 
%                   these indicies, ticks will be shown at these locations, 
%                   no labels.
%       Lims        optional. Two element vector used to set the limits of the
%                   axis.
%   Yaxis [size(PlotData, 1)] struct array, with fields...
%       Same fields as Xaxis, and...
%       RefVal      optional. Plots a reference line at specified y-val.
%                   For no line set to NaN.
%   Data [num series] long strcut array with fields...
%       Name        Name of the series (for legend, optional)
%       PlotType    'scatter' (scattered error bars), 'scatterOnly' (just 
%                   scattered dots), 'line', 'thickLine', or 'errorShading' 
%                   (shades the area in between the error bars)
%       Colour      optional  
%       MakerType   optional (only used for scatter PlotType)
%   Legend  Struct array with fields...
%       Title 
%   Annotate [size(PlotData, 2)]*[size(PlotData, 1)] struct array with fields...
%       Text        Containing text to add to the plot
% varargin  Figure handle for the figure to plot onto. If the old figure
%           has the same subplot structure, then all the data in the old
%           subplots will be retianed.

if ~isfield(PlotStyle, 'General') || strcmp(PlotStyle.General, 'computer')
    plotLineWidth = 4;
    axisLineWidth = 4;
    refLineWidth = 4;
    fontSize = 30;
    tickDirection = 'out';
elseif strcmp(PlotStyle.General, 'paper')
    plotLineWidth = 1;
    axisLineWidth = 1;
    refLineWidth = 1;
    fontSize = 10;
    tickDirection = 'out';
end


%% Setup

% Are we going to use the same x-values for all series?
for iSubplot = 1 : length(PlotData(:))
    if length(PlotData(iSubplot).Xvals) == 1
        PlotData(iSubplot).Xvals ...
            = repmat(PlotData(iSubplot).Xvals, ...
            length(PlotData(iSubplot).Yvals), 1);
    end
end

% Matlab uses a particualar numbering system for subplots. Find an array
% that converts from matrix index to matlab subplot number.
subplotHeight = size(PlotData, 1);
subplotWidth = size(PlotData, 2);

subplotIdx = NaN(subplotWidth, subplotHeight);
subplotIdx(:) = 1 : length(subplotIdx(:));
subplotIdx = subplotIdx';

% Make a new figure or use an existing one?
if isempty(varargin)    
    figHandle = figure('units', 'normalized', 'outerposition', [0 0 1 1]);
else
    figHandle = figure(varargin{1}); 
end


%% Make the plots

for iPltRow = 1 : size(PlotData, 1)
    for iPltCol = 1 : size(PlotData, 2)
        
        % Do the plotting itself
        if (subplotHeight == 1) && (subplotWidth == 1)
            subplotObj = gca;
            hold on    
        else
            subplotObj = subplot(subplotHeight, subplotWidth, ...
                subplotIdx(iPltRow, iPltCol));
            hold on
        end
        
        subplotObj.LineWidth = axisLineWidth;
        subplotObj.FontSize = fontSize;
        
        setupSubplotAxes(PlotStyle, PlotData, iPltRow, iPltCol, fontSize)
        
        % Loop through all the series to be plotted
        for iSeries = 1 : length(PlotData(iPltRow, iPltCol).Yvals)
            
            % What colour should we plot in?
            if isfield(PlotStyle.Data, 'Colour') ...
                && ~isempty(PlotStyle.Data(iSeries).Colour)
                
                plottingColour = PlotStyle.Data(iSeries).Colour;
    
            % Otherwise use default colours
            else
                plottingColour = mT_pickColour(iSeries);
                
                % Store for legend
                PlotStyle.Data(iSeries).Colour = plottingColour;
            end

            % What marker type should we use?
            if isfield(PlotStyle.Data, 'MarkerType') ...
                && ~isempty(PlotStyle.Data(iSeries).MarkerType)
                
                plottingMarker = PlotStyle.Data(iSeries).MarkerType;
            
            % Otherwise use default marker
            else
                plottingMarker = 'o';
                
                % Store for legend
                PlotStyle.Data(iSeries).MarkerType = plottingMarker;                
            end
            
            % Has fading been requested? If not set all fade values to 1
            if ~isfield(PlotData(iPltRow, iPltCol).Yvals(iSeries), 'Fade') ...
                    || isempty(PlotData(iPltRow, iPltCol).Yvals(iSeries).Fade)
                
                PlotData(iPltRow, iPltCol).Yvals(iSeries).Fade = ...
                    ones(size( ...
                    PlotData(iPltRow, iPltCol).Yvals(iSeries).Vals));
            end
            
            
            % Loop through and plot every point
            numPoints = length(PlotData(iPltRow, iPltCol).Xvals(iSeries).Vals);
            assert(numPoints == ...
                length(PlotData(iPltRow, iPltCol).Yvals(iSeries).Vals))
            
            for iXpos = 1 : numPoints
                
                % What is the fading for this point. Note, not used for
                % plot type scatter.
                colourIncFade = plottingColour;
                colourIncFade(end +1) = ...
                    PlotData(iPltRow, iPltCol).Yvals(iSeries).Fade(iXpos);
                
                currentX = ...
                    PlotData(iPltRow, iPltCol).Xvals(iSeries).Vals(iXpos);
                currentY = ...
                    PlotData(iPltRow, iPltCol).Yvals(iSeries).Vals(iXpos);
                    
                
                % What type of plot are we doing?
                if strcmp(PlotStyle.Data(iSeries).PlotType, 'scatterOnly')
                    
                    scatter(currentX, currentY, plottingMarker, ...
                        'MarkerEdgeColor', plottingColour, ...
                        'LineWidth', plotLineWidth)
                    
                elseif strcmp(PlotStyle.Data(iSeries).PlotType, 'scatter')
                    
                    erObj = errorbar(currentX, currentY, ...
                        PlotData(iPltRow, iPltCol...
                        ).Yvals(iSeries).LowerError(iXpos), ...
                        PlotData(iPltRow, iPltCol...
                        ).Yvals(iSeries).UpperError(iXpos), ...
                        'LineStyle','none', 'Color', plottingColour, ...
                        'LineWidth', plotLineWidth);
                    erObj.CapSize = erObj.CapSize*(2/3);
                    
                elseif any(strcmp(PlotStyle.Data(iSeries).PlotType, ...
                        {'line', 'thickLine'}))
                    % Fading will determine half of the line/shading to
                    % the right and half of the line/shading to the left of the
                    % Xval, for line plots.                 
                    currentX = ...
                        PlotData(iPltRow, iPltCol).Xvals(iSeries).Vals(iXpos);
                    currentY = ...
                        PlotData(iPltRow, iPltCol).Yvals(iSeries).Vals(iXpos);
                    
                    if strcmp(PlotStyle.Data(iSeries).PlotType, ...
                            'thickLine')
                        thisWidth = plotLineWidth * 2;
                    else
                        thisWidth = plotLineWidth;
                    end

                    % Start with the lines to the right of the point. There
                    % is nothing to draw to the right if this is the final
                    % data point.
                    if iXpos < numPoints
                        nextX = ...
                            PlotData(iPltRow, iPltCol ...
                            ).Xvals(iSeries).Vals(iXpos +1);
                        nextY = ...
                            PlotData(iPltRow, iPltCol ...
                            ).Yvals(iSeries).Vals(iXpos +1);
                        
                        plot([currentX, (currentX + nextX)/2], ...
                            [currentY, (currentY + nextY)/2], ...
                            'Color', colourIncFade, ...
                            'LineWidth', thisWidth);
                    end

                    % Now the lines to the left of the point. There
                    % is nothing to draw to the right if this is the first
                    % data point.
                    if iXpos > 1
                        prevX = ...
                            PlotData(iPltRow, iPltCol ...
                            ).Xvals(iSeries).Vals(iXpos -1);
                        prevY = ...
                            PlotData(iPltRow, iPltCol ...
                            ).Yvals(iSeries).Vals(iXpos -1); 
                        
                        plot([(prevX + currentX)/2, currentX], ...
                            [(prevY + currentY)/2, currentY], ...
                            'Color', colourIncFade, ...
                            'LineWidth', thisWidth);
                    end
                    
                elseif strcmp(PlotStyle.Data(iSeries).PlotType, ...
                        'errorShading')
                    
                    currentError = [-PlotData(iPltRow, iPltCol ...
                            ).Yvals(iSeries).LowerError(iXpos), ...
                            PlotData(iPltRow, iPltCol ...
                            ).Yvals(iSeries).UpperError(iXpos)] + ...
                            currentY;
                         
                    if iXpos < numPoints
                        
                        nextX = ...
                            PlotData(iPltRow, iPltCol ...
                            ).Xvals(iSeries).Vals(iXpos +1);
                        nextY = ...
                            PlotData(iPltRow, iPltCol ...
                            ).Yvals(iSeries).Vals(iXpos +1);
                        
                        nextError = [-PlotData(iPltRow, iPltCol ...
                            ).Yvals(iSeries).LowerError(iXpos +1), ...
                            PlotData(iPltRow, iPltCol ...
                            ).Yvals(iSeries).UpperError(iXpos +1)] + ...
                            nextY;

                        fill([currentX, currentX, nextX, nextX], ...
                            [currentError, fliplr(nextError)], ...
                            plottingColour, 'Edgecolor','none', ...
                            'FaceAlpha',.25);
                    end
                else
                    error('Unknown plot type requested')
                end
            end
        end
        
        % Add annotations
        if isfield(PlotStyle, 'Annotate')
            labelText = ['{\bf ' PlotStyle.Annotate(iPltRow, iPltCol).Text ' }'];
            
            plotLable = text(-0.12,1.04, ...
                labelText, ...
                'Units', 'Normalized', 'VerticalAlignment', 'Bottom', ...
                'HorizontalAlignment', 'right');
            plotLable.FontSize = fontSize;
        end
        
        
        % Subplot formatting
        set(gca, 'TickDir', tickDirection);
        
        % Reference line?
        if isfield(PlotStyle.Yaxis, 'RefVal') ...
                && ~isnan(PlotStyle.Yaxis(iPltRow).RefVal)
            
            refVal = PlotStyle.Yaxis(iPltRow).RefVal;
            xLimits = get(gca, 'XLim');
            plot(xLimits, [refVal refVal], '--', 'Color', [0.3, 0.3, 0.3], ...
                'LineWidth', refLineWidth)
        end
    end
end
                    

%% Make the legends

% Making the legend is a little complicated in this case. We are going
% to trick MATLAB and draw invisible new lines.

% Set legend
if isfield(PlotStyle, 'Data') && isfield(PlotStyle.Data, 'Name')

    if (subplotHeight == 1) && (subplotWidth == 1)
        % Do nothing, there is only one plot to pick from
    else
        subplot(subplotHeight, subplotWidth, subplotIdx(ceil(subplotHeight/2), end));
        hold on
    end
    
    legendLabels = cell(1, length(PlotStyle.Data));
    for iLabel = 1 : length(legendLabels)
        
        legendLabels{iLabel} = PlotStyle.Data(iLabel).Name;
        legendLine(iLabel) = ...
            errorbar(NaN, NaN, NaN, NaN, ...
            'Color', PlotStyle.Data(iLabel).Colour, ...
            'LineWidth', plotLineWidth); 
    end
    
    legObj = legend(legendLine, legendLabels{:});
    legend boxoff
    
    legObj.FontSize = fontSize;
    legObj.LineWidth = axisLineWidth;
    legObj.ItemTokenSize(1) = 15;
    legObj.Location = 'southeast';
    
    if isfield(PlotStyle, 'Legend') && isfield(PlotStyle.Legend, 'Title')
        title(legObj, PlotStyle.Legend.Title)
    end

end


end


function setupSubplotAxes(PlotStyle, PlotData, iPltRow, iPltCol, fontSize)
% Sets up the axes for the active subplot, using the requested settings.

if isfield(PlotStyle, 'Yaxis') ...
        && isfield(PlotStyle.Yaxis(iPltRow), 'Ticks')
    
    ylim(PlotStyle.Yaxis(iPltRow).Ticks([1, end]))
    yticks(PlotStyle.Yaxis(iPltRow).Ticks)
end

if isfield(PlotStyle, 'Yaxis') ...
        && isfield(PlotStyle.Yaxis(iPltRow), 'TickLabels')
    
    yticklabels(PlotStyle.Yaxis(iPltRow).TickLabels)
end

if isfield(PlotStyle, 'Yaxis') ...
        && isfield(PlotStyle.Yaxis(iPltRow), 'InvisibleTickLablels')
    
    if ~isfield(PlotStyle.Yaxis(iPltRow), 'Ticks')
        error(['Must specify ticks if want to specify invisible ', ...
            'ticks. Otherwise get nasty effects as invisible ticks ', ...
            'functionality works by changing and *freezing* tick ', ...
            'labels.'])
    end
    
    ax = gca;
    labels = string(ax.YTickLabel);
    labels(PlotStyle.Yaxis(iPltRow).InvisibleTickLablels) = ' ';
    ax.YTickLabel = labels;
end

if isfield(PlotStyle, 'Yaxis') ...
        && isfield(PlotStyle.Yaxis(iPltRow), 'Lims') ...
        && ~isempty(PlotStyle.Yaxis(iPltRow).Lims)
    
    ylim(PlotStyle.Yaxis(iPltRow).Lims)
end

if isfield(PlotStyle, 'Xaxis') ...
        && isfield(PlotStyle.Xaxis(iPltCol), 'Ticks')
    
    xlim(PlotStyle.Xaxis(iPltCol).Ticks([1, end]))
    xticks(PlotStyle.Xaxis(iPltCol).Ticks)
end

if isfield(PlotStyle, 'Xaxis') ...
        && isfield(PlotStyle.Xaxis(iPltCol), 'TickLabels')
    
    xticklabels(PlotStyle.Xaxis(iPltCol).TickLabels)
end

if isfield(PlotStyle, 'Xaxis') ...
        && isfield(PlotStyle.Xaxis(iPltCol), 'InvisibleTickLablels')
    
    if ~isfield(PlotStyle.Xaxis(iPltCol), 'Ticks')
        error(['Must specify ticks if want to specify invisible ', ...
            'ticks. Otherwise get nasty effects as invisible ticks ', ...
            'functionality works by changing and *freezing* tick ', ...
            'labels.'])
    end
    
    ax = gca;
    labels = string(ax.XTickLabel);
    labels(PlotStyle.Xaxis(iPltCol).InvisibleTickLablels) = ' ';
    ax.XTickLabel = labels;
end

if isfield(PlotStyle, 'Xaxis') ...
        && isfield(PlotStyle.Xaxis(iPltCol), 'Lims') ...
        && ~isempty(PlotStyle.Xaxis(iPltCol).Lims)
    
    xlim(PlotStyle.Xaxis(iPltCol).Lims)
end

% Whether we want to add labels depends on whether we are at the
% edge of the figure
if isfield(PlotStyle, 'Xaxis') ...
        && isfield(PlotStyle.Xaxis(iPltCol), 'Title')
    
    xLabel = PlotStyle.Xaxis(iPltCol).Title;
else
    xLabel = [];
end

if isfield(PlotStyle, 'Yaxis') ...
        && isfield(PlotStyle.Yaxis(iPltRow), 'Title')
    
    yLabel = PlotStyle.Yaxis(iPltRow).Title;
else
    yLabel = [];
end

if iPltCol == 1
    ylabel(yLabel, 'FontSize',fontSize)
end
if iPltRow == size(PlotData, 1)
    xlabel(xLabel, 'FontSize',fontSize)
end

end

