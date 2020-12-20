function ParamInfo = mT_duplicateParams(ParamInfo, down, across)
% Takes one of the structure of Settings.ParamSets (see README), and duplicates 
% the relevant fields such that this structure now defines a parameter array of 
% shape [i x j], wherebefore the field defined single scalar parameter.
% Properies of the parameters are duplicated downwards, and across, such that, 
% the new parameters are drawn from distributions that correspond
% the dirstibutions used for the original parameter. Note, does this functions
% does not change the field 'PackedOrder'.

% Check the old shape and set the new one
assert(isequal(ParamInfo.UnpackedShape, [1, 1]))
ParamInfo.UnpackedShape(1) = down;
ParamInfo.UnpackedShape(2) = across;

ParamInfo.UnpackedOrder = ...
    1 : (ParamInfo.UnpackedShape(1)*ParamInfo.UnpackedShape(2));

specs = {'InitialVals', 'LowerBound', 'PLB', 'UpperBound', 'PUB'};
optionalSpecs = {'PLB', 'PUB'};

for iSpec = 1 : length(specs)
    % Some of the specs are optional
    if ismember(specs{iSpec}, optionalSpecs)...
        && ~(isfield(ParamInfo, specs{iSpec}))
        warning('PLB and PUB not specified.')
        continue
    end
    
    ParamInfo.(specs{iSpec}) ...
        = @()duplicateFuncCall(ParamInfo.(specs{iSpec}), down, across);
    
    % Check that the outputs of the function is now the intended shape
    if size(ParamInfo.(specs{iSpec})()) ~= ParamInfo.UnpackedShape
        error('Bug')
    end
end

end


function duplicatedCall = duplicateFuncCall(funcHandle, down, across)
% Instead of calling a function once, call it [down x across] times and
% concatinate the reults into a matrix.

% What size output does the function produce on its own?
outSize = size(funcHandle());

duplicatedCall = NaN(outSize(1) * down, outSize(2) * across);

% Make the calls
for iCallDown = 1 : down
    for iCallAcross = 1 : across
        duplicatedCall( ...
            (((iCallDown-1)*outSize(1))+1) : (iCallDown*outSize(1)),  ...
            (((iCallAcross-1)*outSize(2))+1) : (iCallAcross*outSize(2))) ...
            = funcHandle();
    end
end

assert(~any(isnan(duplicatedCall(:))))
    
end

