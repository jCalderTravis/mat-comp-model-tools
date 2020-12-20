function [ordinalVar, indecisionPoint, varBinProp, breaks] = mT_makeVarOrdinal(...
    Settings, inVar, blockType, flip)
% Divides up variable var into bins. Binning is done seperately for different 
% blockTypes if requested. To exclude a trial provide blockType NaN.

% INPUT
% Settings  Strcut with fields:
%           DataType    Should ordinalVar be of the ordinal data type, or should
%                       it be integers. ('ordinal' or 'integer')
%           BreakTies   (true or false)
%           Flip        Use the flip vector or ignore (true or false)
%           EnforceZeroPoint   Enforce that one of the bin edges is at 
%                       Settings.CenterPoint.
%           CenterPoint The value of the center point, in the units used in 'inVar'
%           NumBins     How many bins to use?
%           BinsBelow   Only used in the case EnforceZeroPoint is true. How many bins
%                       to use below the center point?
%           SepBinning  Bin seperately for the different block types (true), or
%                       treat all data together during the binning process
%                       (false).
% inVar     Data vector
% blockType Vector of length var.
%           'varBinProp' gives statistics seperately for each block type, and
%           binning of the variable itself is done seperately for different
%           blocks if 'Settings.SepBinning' is set to true.
%           To exclude a trial provide blockType NaN.
% flip      (optional) Binary vector of lenth vec. If a value is 1, then the corresponding
%           value in vec is changed to be its mirror about centerPoint.
%           I.e. new value = -(old value - centerPoint) + centerPoint

% OUTPUT
%   indecisionPoint 
%           [num block types x 1] array specifying the bin such that to the
%           right edge of this bin is the CenterPoint
%   varBinProp
%           [num conf categories x num block types] array. Represents 
%           proportion of trials in each confidence category, seperately for
%           the two block types.
%   breaks  The values on the orgiginal scale (after flipping) where the bin
%           edges lie


if ~strcmp(Settings.DataType, 'ordinal') && ...
        ~strcmp(Settings.DataType, 'integer')
    error('Incorrect specification of settings.')
end

% Check shapes of input
if Settings.Flip
    toCheck = {inVar, blockType, flip};
else
    toCheck = {inVar, blockType};
end

for iVar = 1 : length(toCheck)
    if size(toCheck{iVar}, 2) ~= 1
        error('Incorrect use of input arguemnts. Vectors should be comlumns')
    end
end

if length(inVar) < Settings.NumBins
    error('Must be more trials that the requrested number of bins')
end


%% Break ties
% Add a neglidgible amount of noise to the data in order to break ties
if Settings.BreakTies
    contVar = NaN(length(inVar), 1);
    contVar(~isnan(inVar)) = inVar(~isnan(inVar)) + ...
        ((10^(-10)) * rand(sum(~isnan(inVar)), 1));
else
    contVar = inVar;
end


%% Flip data
if Settings.Flip
    if isnan(Settings.CenterPoint)
        error('Center point must be specified if flip requested')
    end
    
    contVar = contVar - Settings.CenterPoint;
    contVar(flip == 1) = - contVar(flip == 1);
    % Return to the original centering
    contVar = contVar + Settings.CenterPoint;
end


%% Make variable ordinal

% Are we binning all data together or in seperate groups?
if Settings.SepBinning
    binningGroup = blockType;
else
    binningGroup = blockType;
    binningGroup(~isnan(binningGroup)) = 1;
end

% Give the categories names
bins = {};
for iCat = 1 : Settings.NumBins
    if strcmp(Settings.DataType, 'ordinal')
        bins{end +1} = num2str(iCat);
    else
        bins{end +1} = iCat; 
    end
end

% Bin the variable based on values in the different binningGroups seperately
binningGroupsList = unique(binningGroup);
binningGroupsList(isnan(binningGroupsList)) = [];


breaks = cell(length(unique(binningGroupsList)), 1);
ordinalVarByBlock = cell(length(unique(binningGroupsList)), 1);
indecisionPoint = cell(max(unique(binningGroupsList)), 1);

for iBinGroup = 1 : length(binningGroupsList)
    currentBin = binningGroupsList(iBinGroup);
    
    if Settings.EnforceZeroPoint 
        % Find the proportion of trials below centerPoint so that this can be
        % imposed as a boundary
        trialsBelow = sum(contVar(binningGroup == currentBin) ...
            < Settings.CenterPoint);
        propBelow = trialsBelow / sum(binningGroup == currentBin);
        
        % Then divide up the spaces above and below this evenly.
        binsBelow = Settings.BinsBelow;
        binsAbove = Settings.NumBins - binsBelow;
        
        pDivisionsBelow = linspace(0, propBelow, (binsBelow +1));
        pDivisionsAbove = linspace(propBelow, 1, (binsAbove +1));
        
        pDivisions = [pDivisionsBelow, pDivisionsAbove(2 : end)];
        
        breaks{iBinGroup} = ...
            quantile(contVar(binningGroup == currentBin), pDivisions);
        
        % After which category does the centerPoint fall?
        indecisionPoint{currentBin} = bins{binsBelow};
    else
        % In this case we can just divide up the entirity of the data using the 
        % desired number of quantiles.
        quantileSize = 1 / Settings.NumBins;
        pDivisions = 0 : quantileSize : 1;
        
        breaks{iBinGroup} = ...
            quantile(contVar(binningGroup == currentBin), pDivisions);
    end
    
    if strcmp(Settings.DataType, 'ordinal')
        ordinalVarByBlock{iBinGroup} = ordinal(contVar, ...
            bins, [], breaks{iBinGroup});
        warning('This case is work in progress.')
        
    elseif strcmp(Settings.DataType, 'integer')
        ordinalVarByBlock{iBinGroup} = ...
            discretize(contVar, breaks{iBinGroup}, 'IncludedEdge', 'right'); 
    end
end

% Code check
if length(breaks) ~= length(ordinalVarByBlock)
    error('bug')
end

% Combine data from the seperate block-wise binning procedures. First, fill a
% vector with NaNs or undefined.
if strcmp(Settings.DataType, 'ordinal')
    warning('This case is work in progress.')
    
    ordinalVar = ordinalVarByBlock{1};
    firstUndefined = find(isundefined(ordinalVar));
    
    % If there were no undefined trials in block 1, try and find them in block 2
    if isempty(firstUndefined) && (length(ordinalVarByBlock) >1)
        ordinalVar = ordinalVarByBlock{2};
        firstUndefined = find(isundefined(ordinalVar));
    end
    
    % Provided we have found at least one undefined case...
    if ~isempty(firstUndefined)
        firstUndefined = firstUndefined(1);
        ordinalVar(:) = ordinalVar(firstUndefined);
    end
elseif strcmp(Settings.DataType, 'integer')
    ordinalVar = NaN(size(ordinalVarByBlock{1}));
    assert(isequal(size(ordinalVar), size(inVar)))
end

% If we have binned all data together, still provide a indecision point for each
% block.
if ~Settings.SepBinning
    blockTypes = unique(blockType);
    blockTypes(isnan(blockTypes)) = [];
    
    indecisionPoint = repmat(indecisionPoint, 1, length(blockTypes));
    assert(isequal(size(indecisionPoint), [1, length(blockTypes)]))
end

for iBinGroup = 1 : length(binningGroupsList)    
    currentBin = binningGroupsList(iBinGroup);
    
    ordinalVar(binningGroup == currentBin) = ...
        ordinalVarByBlock{iBinGroup}(binningGroup == currentBin);
end


% Check the NaNs are still NaNs
if strcmp(Settings.DataType, 'ordinal') && ...
        (any((isnan(inVar)|isnan(blockType)) & (~isundefined(ordinalVar))) || ...
        any((~(isnan(inVar) | isnan(blockType)) & isundefined(ordinalVar))))  
    error('Code not functioning as expected')
    
elseif strcmp(Settings.DataType, 'integer') && ...
        (any((isnan(inVar)|isnan(blockType)) & (~isnan(ordinalVar))) || ...
        any((~(isnan(inVar) | isnan(blockType)) & isnan(ordinalVar))))
    error('Code not functioning as expected')
end


%% Count proportion of cases in each bin and block

bins = unique(ordinalVar);

if strcmp(Settings.DataType, 'ordinal')
    bins(isundefined(bins)) = [];
else
    bins(isnan(bins)) = [];
end

if length(bins) ~= Settings.NumBins; error('Bug'); end

blockTypes = unique(blockType);
blockTypes(isnan(blockTypes)) = [];

varBinProp = NaN(length(bins), length(blockTypes));

% Seperately for each block
for iBlockType = blockTypes'
    validCases = sum(~isnan(inVar(blockType == iBlockType)));

    for iBin = 1 : length(bins)
        varBinProp(iBin, iBlockType) = ...
            sum(ordinalVar(blockType == iBlockType) == bins(iBin)) ...
            / validCases;
    end
end

