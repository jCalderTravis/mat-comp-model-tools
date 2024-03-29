function [figHandle, PtpntPlotData] = mT_plotVariableRelations(DSet, ...
    XVars, YVars, Series, PlotStyle, varargin)
% Plots various relationships between the x-variables variables 
% and the y-variables (after binning the x-variables), in subplots.

% INPUT
% XVars     [num x-variables] long struct array with fields...
%   ProduceVar      Function handle. Function accepts 'DSet.P(i).Data' (see
%                   standard data strcuture information in README).
%                   Function produces [num trials] long vector of values of this
%                   variable.
%   NumBins         When the x-variable is binned for plotting and for calculation
%                   of the y-variable, how many bins should be used? If the data
%                   is already binned, pass 'prebinned'.
%   FindIncludedTrials
%                   (optional)
%                   Function handle. Function accepts 'DSet.P(i).Data' and 
%                   produces a [num trials] long logical of trials to include
%                   when evaluating this x-variable. Note that trials are only
%                   included if they meet all inclusion criteria, see 'Series'.
%   EnforcedBins    vector. Optional. Only use when the corresponding 
%                   XVars.NumBins is 'prebinned'. The vector gives bin
%                   values. These bin values will always be plotted even if
%                   there are no corresponding included trials.
% 
% YVars     [num y-variables] long struct array with fields...
%   ProduceVar      Function handle. Function accepts 'DSet.P(i).Data' (see
%                   standard data strcuture information in README), and 
%                   'binTrials' a [num trials] long logical, with a one for
%                   every trial in the bin currently being evaluated, and that 
%                   meets all inclusions criteria (for the YVar and the Series).
%                   Function produces a single value, the value of the
%                   y-variable for this bin.
%   FindIncludedTrials
%                   Function handle. Function accepts 'DSet.P(i).Data' and 
%                   produces a [num trials] long logical of trials to include
%                   when evaluating this y-variable. Note that trials are only
%                   included if they meet all inclusion criteria, see 'Series'.
%   ProduceTrialByTrialVar Optional. Function handle accpeting 'DSet.P(i).Data'.
%                   If provided, function also computes and returns
%                   the correlation between the x-variables and the variable
%                   produced by this function handle. Results can be found in 
%                   PtpntPlotData. % TODO explain more how the results are
%                   stored
%
% Series    [num series] long struct array. Each series will be plotted in 
%           every subplot. Contains fields...
%   FindIncludedTrials
%                   Function handle. Function accepts 'DSet.P(i).Data' and 
%                   produces a [num trials] long logical of trials to include
%                   when evaluating this series. Note that trials are only
%                   included if they meet all inclusion criteria, see 
%                   'XVars' and 'YVars'.
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
%   Yaxis [size(PlotData, 1)] struct array with fields...
%       Same fields as Xaxis, and...
%       RefVal      optional. Plots a reference line at specified y-val.
%                   For no line set to NaN.
%       SigHeight   optional. The height in data coordinates on the y-axis
%                   to plot lines indicating significance.
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
% varargin{1}  Figure handle for the figure to plot onto. If the old figure
%   has the same subplot structure, then all the data in the old
%   subplots will be retianed.
% varagin{2} If set to 'median' use median for averaging over participants.
%   Otherwise set to 'mean' or don't use (default is 'mean'). Note in the 
%   case of 'median' error bars still reflect SEM, which doesn't really make 
%   sense.
% varargin{3}: string filepath. If provided, cluster-based statistics are
%   performed and signiifcant points are indicated on the plot. The 
%   provided filepath is used for saving temporary files. May only be used
%   for series where PlotStyle.Data(iS).PlotType is 'scatter', to avoid 
%   ambiguitiy (multiple series may use the same colour but different 
%   plot types, but significant points are only indicated through colour).

% HISTORY
% Reviewed 2020
% Significance testing added 2023

if (~isempty(varargin)) && (~isempty(varargin{1}))
    figHandle = varargin{1};
    hold on
else
    figHandle = figure;
end

if (length(varargin)>=2) && (~isempty(varargin{2}))
    averaging = varargin{2};
else
    averaging = 'mean';
end

if ~ismember(averaging, {'mean', 'median'}); error('Incorrect input.'); end

if (length(varargin)>=3) && (~isempty(varargin{3}))
    sigTmpDir = varargin{3};
else
    sigTmpDir = [];
end


%% Binning per participant

% Initialise
PtpntPlotData.BinX = [];
PtpntPlotData.BinY = [];
PtpntPlotData = repmat(PtpntPlotData, length(YVars), length(XVars));

for iY = 1 : length(YVars)
    for iX = 1 : length(XVars)
        
        % How many bins to we have/want?
        if ~strcmp(XVars(iX).NumBins, 'prebinned')
            numBins = XVars(iX).NumBins;
            
        elseif strcmp(XVars(iX).NumBins, 'prebinned')
            numBins = determineBinNumber(DSet, XVars, iX, YVars, iY, Series);
            
        end

        PtpntPlotData(iY, iX).BinX = ...
            NaN(length(Series), numBins, length(DSet.P));
        PtpntPlotData(iY, iX).BinY = ...
            NaN(length(Series), numBins, length(DSet.P));
    end
end

for iPtpnt = 1 : length(DSet.P)    
    for iY = 1 : length(YVars)
        for iS = 1 : length(Series)
            for iX = 1 : length(XVars)
                xValues = XVars(iX).ProduceVar(DSet.P(iPtpnt).Data);
                
                % Which data meets all inclusion conditions?
                includedData = findIncludedTrials(DSet, iPtpnt, ...
                    XVars, iX, YVars, iY, Series, iS);
                
                % Compute correlation if requested
                if isfield(YVars, 'ProduceTrialByTrialVar')
                    trialByTrialVar ...
                        = YVars(iY).ProduceTrialByTrialVar(DSet.P(iPtpnt).Data);
                    
                    correlation = corr(xValues(includedData), ...
                        trialByTrialVar(includedData));
                    
                    if ~(size(correlation) == [1, 1]); error('Bug'); end
                    if isnan(correlation); error('Bug'); end
                    
                    PtpntPlotData(iY, iX).Correlations(iS, iPtpnt) ...
                        = correlation;
                end
                
                % Bin data meeting the inclusion conditions
                if ~strcmp(XVars(iX).NumBins, 'prebinned')
                    
                    % To exclude data we pass the 'blockType' argument of 
                    % the below function as NaNs.
                    blockType = double(includedData);
                    blockType(blockType == 0) = NaN;
                    
                    % Is there any data to bin?
                    if sum(~isnan(blockType))==0
                        warning(['No data for x ' num2str(iX) ...
                            ', y ' num2str(iY) ' s, ' num2str(iS) '.'])
                        continue
                    end
                    
                    BinSettings.DataType = 'integer';
                    BinSettings.BreakTies = false;
                    BinSettings.Flip = false;
                    BinSettings.EnforceZeroPoint = false;
                    BinSettings.NumBins = XVars(iX).NumBins;
                    BinSettings.SepBinning = false;
                    
                    [ordinalVar, ~, ~] = mT_makeVarOrdinal(BinSettings, xValues, ...
                        blockType, []);
                    assert(isequal(isnan(ordinalVar), ~includedData))
                else
                    ordinalVar = xValues;
                    ordinalVar(~includedData) = NaN;
                end
                
                
                bins = unique(ordinalVar);
                bins(isnan(bins)) = [];
                
                % Apply any enforced bins
                if isfield(XVars(iX), 'EnforcedBins') && (...
                        ~isempty(XVars(iX).EnforcedBins))
                    
                    if ~strcmp(XVars(iX).NumBins, 'prebinned')
                        error(['This combination of options is ', ...
                            'not permitted.'])
                    end
                    bins = unique([bins(:); XVars(iX).EnforcedBins(:)]);
                end
                
                for iBin = 1 : length(bins)
                    binTrials = ordinalVar == bins(iBin);
                    
                    % We will use the average xVar value of the data points
                    % in the bin as the bin's x-position. If there are no
                    % cases, which can occour when using EnforcedBins,
                    % just use the bin value itself.
                    if sum(binTrials) == 0
                        assert(isfield(XVars(iX), 'EnforcedBins'))
                        assert(~isempty(XVars(iX).EnforcedBins))
                        assert(strcmp(XVars(iX).NumBins, 'prebinned'))
                        
                        PtpntPlotData(iY, iX).BinX(iS, iBin, iPtpnt) ...
                            = bins(iBin);
                    else
                        PtpntPlotData(iY, iX).BinX(iS, iBin, iPtpnt) ...
                            = mean(xValues(binTrials));
                    end
                    
                    % Compute the y-position
                    PtpntPlotData(iY, iX).BinY(iS, iBin, iPtpnt) ...
                        = YVars(iY).ProduceVar(DSet.P(iPtpnt).Data, binTrials);
                    
                    if isnan(PtpntPlotData(iY, iX).BinY(iS, iBin, iPtpnt))
                        error('Plot value is nan.')
                    end
                end
            end
        end
    end
end
      

%% Averaging over participants

% We now average the results over participants, taking the mean bin x- and
% y-positions.
for iY = 1 : length(YVars)
    for iX = 1 : length(XVars)
        
        if strcmp(averaging, 'mean')
            averageXdata = mean(PtpntPlotData(iY, iX).BinX(:, :, :), 3);
            averageYdata = mean(PtpntPlotData(iY, iX).BinY(:, :, :), 3);
            SEM = std(PtpntPlotData(iY, iX).BinY(:, :, :), 0, 3) ...
                ./ (sum(~isnan(PtpntPlotData(iY, iX).BinY(:, :, :)), 3).^(1/2));
            
        elseif strcmp(averaging, 'median')
            averageXdata = median(PtpntPlotData(iY, iX).BinX(:, :, :), 3);
            averageYdata = median(PtpntPlotData(iY, iX).BinY(:, :, :), 3);
            SEM = std(PtpntPlotData(iY, iX).BinY(:, :, :), 0, 3) ...
                ./ (sum(~isnan(PtpntPlotData(iY, iX).BinY(:, :, :)), 3).^(1/2));
        end
        
        for iS = 1 : length(Series)
            AvPlotData(iY, iX).Xvals(iS).Vals = averageXdata(iS, :);
            AvPlotData(iY, iX).Yvals(iS).Vals = averageYdata(iS, :);
            AvPlotData(iY, iX).Yvals(iS).UpperError = SEM(iS, :);
            AvPlotData(iY, iX).Yvals(iS).LowerError = SEM(iS, :);

            % Significance testing
            if ~isempty(sigTmpDir)
                if ~strcmp(PlotStyle.Data(iS).PlotType, 'scatter')
                    error('See comments at beginning of function')
                end

                % Perform cluster-based permutation tests assuming that
                % the data are ordered, so check this.
                theseXVals = AvPlotData(iY, iX).Xvals(iS).Vals;
                assert(all(diff(theseXVals(:))>0))

                sigNumPtpnt = length(DSet.P);
                sigNumBins = length(theseXVals);
                allPtpntYVals = PtpntPlotData(iY, iX).BinY(iS, :, :);
                assert(sigNumPtpnt == size(allPtpntYVals, 3))
                assert(sigNumBins == size(allPtpntYVals, 2))

                allPtpntYVals = permute(allPtpntYVals, [3, 2, 1]);
                assert(isequal(size(allPtpntYVals), ...
                    [sigNumPtpnt, sigNumBins]))
                
                [~, sig] = mT_runPermutationTest(allPtpntYVals, sigTmpDir);
                assert(isequal(size(sig), [sigNumBins, 1]))
                AvPlotData(iY, iX).Yvals(iS).Sig = sig;
                
                if ~any(sig)
                    disp(['Significance testing was perfromed ', ...
                        'but no points achieved significance.'])
                end
            end
        end
    end
end

figHandle = mT_plotSetsOfSeries(AvPlotData, PlotStyle, figHandle);  


end


function includedData = findIncludedTrials(DSet, iPtpnt, ...
    XVars, iX, YVars, iY, Series, iS)
% Find the trials meeting all inclusion criteria

if isfield(XVars, 'FindIncludedTrials')
    
    includedData ...
        = XVars(iX).FindIncludedTrials(DSet.P(iPtpnt).Data) ...
        & YVars(iY).FindIncludedTrials(DSet.P(iPtpnt).Data) ...
        & Series(iS).FindIncludedTrials(DSet.P(iPtpnt).Data);
else
    includedData ...
        = YVars(iY).FindIncludedTrials(DSet.P(iPtpnt).Data) ...
        & Series(iS).FindIncludedTrials(DSet.P(iPtpnt).Data);
end

end


function numBins = determineBinNumber(DSet, XVars, iX, YVars, iY, Series)
% Work out how many bins there are in the prebinned data. Do calcuation for 
% each series and participant. Note the code can only deal with
% the case where there are the same number of bins for each
% series, and participant.
numBins = NaN(length(Series), length(DSet.P));

for iPtpnt = 1 : length(DSet.P)
    xValues = XVars(iX).ProduceVar(DSet.P(iPtpnt).Data);
    
    for iS = 1 : length(Series)
        includedData = findIncludedTrials(DSet, iPtpnt, XVars, iX, ...
            YVars, iY, Series, iS);
        
        bins = unique(xValues(includedData));
        bins(isnan(bins)) = [];
        
        if isfield(XVars(iX), 'EnforcedBins') && (...
                ~isempty(XVars(iX).EnforcedBins))
            
            if ~strcmp(XVars(iX).NumBins, 'prebinned')
                error('This combination of options is not permitted.')
            end
            bins = unique([bins(:); XVars(iX).EnforcedBins(:)]);
        end
        
        numBins(iS, iPtpnt) = length(bins);
    end
end
                
numBins = unique(numBins(:));

if length(numBins) ~= 1
    error(['code can only deal with ', ...
        'the case where there are the same number of bins for each', ...
        'series and participant.'])
end

end
   

