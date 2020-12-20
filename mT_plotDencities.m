function figHandle = mT_plotDencities(DSet, XVars, Rows, Series, ...
    PlotStyle, ptpntNum, varargin)
% Produces subplots of histograms

% INPUT
% XVars     [num x-variables] long struct array with fields...
%   ProduceVar      Function handle. Function accepts 'DSet.P(i).Data' (see
%                   standard data strcuture information in README).
%                   Function produces [num trials] long vector of values of this
%                   variable.
%   NumBins         Number of histogram bins to use
%   FindIncludedTrials
%                   (optional)
%                   Function handle. Function accepts 'DSet.P(i).Data' and
%                   produces a [num trials] long logical of trials to include
%                   when evaluating this x-variable. Note that trials are only
%                   included if they meet all inclusion criteria, see 'Series'.
%
% Rows     [num subplot rows] long struct array with fields...
%   FindIncludedTrials
%                   Function handle. Function accepts 'DSet.P(i).Data' and
%                   produces a [num trials] long logical of trials to include
%                   when evaluating the histograms in this subplot row.
%                   Note that trials are only
%                   included if they meet all inclusion criteria, see 'Series'.
%
% Series    [num series] long struct array. Each series will be plotted in
%           every subplot. Contains fields...
%   FindIncludedTrials
%                   Function handle. Function accepts 'DSet.P(i).Data' and
%                   produces a [num trials] long logical of trials to include
%                   when evaluating this series. Note that trials are only
%                   included if they meet all inclusion criteria.
%
% PlotStyle struct array with fields...
%   General
%       Which defaults to use, 'computer' or 'paper'
%   Scale
%       Scales such that the physical area under the probability distributions (which is
%       the same for all series and scales) is bigger or smaller. 5 is a
%       sensible first value.
%   Annotate
%   Xaxis [num x-variables] struct array with fields...
%       Title       optional
%       Ticks       optional
%       TickLabels   optional
%       InvisibleTickLablels optional. Vector which gives indecies of
%       TickLabels. For the labels and ticks corresponding to these indicies,
%       ticks will be shown at these locations, no labels.
%   Rows  [num subplot rows] long struct array with fields...
%       Title       optional
%   Data [num series] long strcut array with fields...
%       Name        Name of the series (for legend, optional)
%       Colour      optional
%       LineStyle   optional string. Options are the standard MATLAB options 
%                   ('-', '--', ':', '-.')
% ptpntNum  Which participant to plot for?
% varargin  Figure handle for the figure to plot onto. If the old figure
%           has the same subplot structure, then all the data in the old
%           subplots will be retianed.

if ~isempty(varargin)
    figHandle = varargin{1};
    hold on
else
    figHandle = figure;
end

if ~isfield(PlotStyle, 'General') || strcmp(PlotStyle.General, 'computer')
    plotLineWidth = 4;
    axisLineWidth = 4;
    refLineWidth = 2;
    fontSize = 30;
    tickDirection = 'out';
elseif strcmp(PlotStyle.General, 'paper')
    plotLineWidth = 1.5;
    axisLineWidth = 1;
    refLineWidth = 0.5;
    fontSize = 10;
    tickDirection = 'out';
end

% Matlab uses a particualar numbering system for subplots. Find an array
% that converts from matrix index to matlab subplot number.
subplotWidth = length(XVars);
subplotHeight = length(Rows);

subplotIdx = NaN(subplotWidth, subplotHeight);
subplotIdx(:) = 1 : length(subplotIdx(:));
subplotIdx = subplotIdx';


%% Make the plots
for iPltRow = 1 : subplotHeight
    for iPltCol = 1 : subplotWidth
        % Do the plotting itself
        if (subplotHeight == 1) && (subplotWidth == 1)
            subplotObj = gca;
            hold on
        else
            subplotObj = subplot(subplotHeight, subplotWidth, ...
                subplotIdx(iPltRow, iPltCol));
            hold on
        end
        
        % Loop through all the series to be plotted
        for iSeries = 1 : length(Series)
            
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
            
            
            % Plotting time!
            relData = XVars(iPltCol).ProduceVar(DSet.P(ptpntNum).Data);
            incTrials = findIncludedTrials(DSet, ptpntNum, ...
                XVars, iPltCol, Rows, iPltRow, Series, iSeries);
            
            [histVals, edges] = histcounts(relData(incTrials), ...
                XVars(iPltCol).NumBins, ...
                'Normalization', 'pdf');
            
            centres = edges(1:end-1) + (0.5*diff(edges));
            
            % Have we requested a specific line style?
            if isfield(PlotStyle, 'Data') ...
                && isfield(PlotStyle.Data(iSeries), 'LineStyle') ...
                && ~isempty(PlotStyle.Data(iSeries).LineStyle)
                
                lineStyle = PlotStyle.Data(iSeries).LineStyle;
            else
                lineStyle = '-';
                PlotStyle.Data(iSeries).LineStyle = '-';
            end
           
            plot(centres, histVals, ...
                'Color', plottingColour, ...
                'LineWidth', plotLineWidth, ...
                'LineStyle', lineStyle);
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
        
        % Remove y-ticks
        set(gca,'ytick',[])
        set(gca,'yticklabel',[])
        
        % Set y-limits in a way to ensure constant area accross all plots
        xScale = diff(xlim);
        yEndPoints = [0, PlotStyle.Scale]/xScale;
        ylim(yEndPoints)
        
        % Titles
        if isfield(PlotStyle, 'Xaxis') ...
                && isfield(PlotStyle.Xaxis(iPltCol), 'Title')
            xLabel = PlotStyle.Xaxis(iPltCol).Title;
        else
            xLabel = [];
        end
        
        if isfield(PlotStyle, 'Rows') ...
                && isfield(PlotStyle.Rows(iPltRow), 'Title')
            yLabel = PlotStyle.Rows(iPltRow).Title;
        else
            yLabel = [];
        end
        
        if iPltCol == 1; ylabel(yLabel, 'FontSize',fontSize); end
        if iPltRow == subplotHeight; xlabel(xLabel, 'FontSize',fontSize); end
        
        % Other properties
        subplotObj.LineWidth = axisLineWidth;
        subplotObj.FontSize = fontSize;
        set(gca, 'TickDir', tickDirection);
       
        % Add annotations
        if isfield(PlotStyle, 'Annotate')     
            labelText = ['{\bf ' PlotStyle.Annotate(iPltRow, iPltCol).Text ' }'];
            
            plotLable = text(-0.08,1.04, ...
                labelText, ...
                'Units', 'Normalized', 'VerticalAlignment', 'Bottom');
            plotLable.FontSize = fontSize;
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
        subplot(subplotHeight, subplotWidth, ...
            subplotIdx(ceil(subplotHeight/2), end));
        hold on
    end
    
    legendLabels = cell(1, length(PlotStyle.Data));
    for iLabel = 1 : length(legendLabels)
        
        legendLabels{iLabel} = PlotStyle.Data(iLabel).Name;
        legendLine(iLabel) = ...
            errorbar(NaN, NaN, NaN, NaN, ...
            'Color', PlotStyle.Data(iLabel).Colour, ...
            'LineWidth', plotLineWidth, ...
            'LineStyle', PlotStyle.Data(iLabel).LineStyle);
    end
    
    legObj = legend(legendLine, legendLabels{:});
    legend boxoff
    
    legObj.FontSize = fontSize;
    legObj.LineWidth = axisLineWidth;
    legObj.ItemTokenSize(1) = 30; 
end


end

function includedData = findIncludedTrials(DSet, iPtpnt, XVars, iX, ...
    Row, iR, Series, iS)
% Find the trials meeting all inclusion criteria

if isfield(XVars, 'FindIncludedTrials')
    includedData ...
        = XVars(iX).FindIncludedTrials(DSet.P(iPtpnt).Data) ...
        & Row(iR).FindIncludedTrials(DSet.P(iPtpnt).Data) ...
        & Series(iS).FindIncludedTrials(DSet.P(iPtpnt).Data);
else
    includedData ...
        = Row(iR).FindIncludedTrials(DSet.P(iPtpnt).Data) ...
        & Series(iS).FindIncludedTrials(DSet.P(iPtpnt).Data);
end

end

