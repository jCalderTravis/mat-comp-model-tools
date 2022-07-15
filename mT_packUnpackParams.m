function outData = mT_packUnpackParams(direction, Settings, inData)
% Pack the parameters into a vector, or unpack into a strcuture with a field for
% each set of params

% INPUT
% direction: 'pack', 'unpack', or 'packTest'. In the case of 'packTest',
% the param structure is packed, unpacked, and packed again, and it is checked
% that these operations do not change the parameters in two ways (see code).
% Settings: The standard settings struct. See findMaximumLikelihood. The 
% field 'Params' is used to determine how to pack and unpack.
% inData: The param data

if length(Settings) ~= 1; error('Incorrect use of input arguments'); end

if strcmp(direction, 'packTest')
    testFun(Settings, inData);
    return
end

% Find the information on the intended location of the parameters when packed
% and when unpacked. This information is given in settings.
paramNames = cell(length(Settings.Params), 1);
packedParamOrder = cell(1, length(Settings.Params));
unpackedParamOrder = cell(1, length(Settings.Params));

for iParam = 1 : length(Settings.Params)    
    paramNames{iParam} = Settings.Params(iParam).Name;
    packedParamOrder{iParam} = Settings.Params(iParam).PackedOrder;
    unpackedParamOrder{iParam} = Settings.Params(iParam).UnpackedOrder;
end


%% Packing and unpacking
if strcmp(direction, 'unpack')
    
    % Check input. In this case the input must be a row vector.
    assert(isnumeric(inData))
    assert(size(inData, 1) == 1)
    
    % Time to unpack...
    for iParam = 1 : length(paramNames)
        outData.(paramNames{iParam}) = ...
            NaN(Settings.Params(iParam).UnpackedShape);
        
        % Is the parameter stored on a log scale when packed? If so exponentiate
        % as we unpack it. Is the parameter stored on a square root scale when 
        % packed? If so square as we unpack it. If both options are requested 
        % throw an error.
        if isfield(Settings.Params, 'FitLog') ...
                && Settings.Params(iParam).FitLog ...
                && isfield(Settings.Params, 'FitSqrt') ...
                && Settings.Params(iParam).FitSqrt
            error(['Cannot use both the log and the square root transform at ' ...
                'the same time.'])
        end
        
        theseParams = inData(packedParamOrder{iParam});
        
        if isfield(Settings.Params, 'FitLog') && Settings.Params(iParam).FitLog
            theseParams = exp(theseParams);
            logOrSqrt = true;
        elseif isfield(Settings.Params, 'FitSqrt') ...
                && Settings.Params(iParam).FitSqrt
            theseParams = theseParams.^2;
            logOrSqrt = true;
        else
            logOrSqrt = false;
        end
        
        % Note the order of scaling and offseting must be opposite to the order
        % used when packing. Do not allow with FitLog or FigSqrt.
        if isfield(Settings.Params, 'FitScale')
            if logOrSqrt && (Settings.Params(iParam).FitScale ~= 1)
                error('Cannot use together.')
            end
            theseParams = theseParams / Settings.Params(iParam).FitScale;
        end
        
        if isfield(Settings.Params, 'FitOffset')
            if logOrSqrt && (Settings.Params(iParam).FitOffset ~= 0)
                error('Cannot use together.')
            end
            theseParams = theseParams - Settings.Params(iParam).FitOffset;
        end
        
        outData.(paramNames{iParam})(unpackedParamOrder{iParam}) = theseParams;
        assert(~any(isnan(outData.(paramNames{iParam})(:))))
    end
    
    
elseif strcmp(direction, 'pack')
    
    % Check input. With packing selected, the input must be a struct
    assert(isstruct(inData))
        
    % Initialise the row vector to pack
    outData = NaN(1, max(cellfun(@max, packedParamOrder)));
    
    % Time to pack...
    for iParam = 1 : length(paramNames)
        
        % Is the parameter stored on a log scale when packed? Is the parameter
        % stored on a square root scale when packed? If both options are requested 
        % throw an error.
        if isfield(Settings.Params, 'FitLog') ...
                && Settings.Params(iParam).FitLog ...
                && isfield(Settings.Params, 'FitSqrt') ...
                && Settings.Params(iParam).FitSqrt
            error(['Cannot use both the log and the square root transform at ' ...
                'the same time.'])
        end
        
        if isfield(Settings.Params, 'FitLog') && Settings.Params(iParam).FitLog
            theseParams = ...
                log(inData.(paramNames{iParam})(unpackedParamOrder{iParam}));
            logOrSqrt = true;
        elseif isfield(Settings.Params, 'FitSqrt') && Settings.Params(iParam).FitSqrt
            theseParams = ...
                sqrt(inData.(paramNames{iParam})(unpackedParamOrder{iParam}));
            logOrSqrt = true;
        else
             theseParams = ...
                inData.(paramNames{iParam})(unpackedParamOrder{iParam});
            logOrSqrt = false;
        end
        
        % Note the order of scaling and offseting must be opposite to the order
        % used when unpacking.
        if isfield(Settings.Params, 'FitOffset')
            if logOrSqrt && (Settings.Params(iParam).FitOffset ~= 0)
                error('Cannot use together.')
            end
            theseParams = theseParams + Settings.Params(iParam).FitOffset;
        end
        
        if isfield(Settings.Params, 'FitScale')
            if logOrSqrt && (Settings.Params(iParam).FitScale ~= 1)
                error('Cannot use together.')
            end
            theseParams = theseParams * Settings.Params(iParam).FitScale;
        end
        
        outData(packedParamOrder{iParam}) = theseParams;    
    end
else    
    error('Bug: Input arguments incorrect.')
end

end

function testFun(Settings, Unpacked1)
% Test that packing and unpacking does not change the parameters.

Packed1 = mT_packUnpackParams('pack', Settings, Unpacked1);
Unpacked2 = mT_packUnpackParams('unpack', Settings, Packed1);
Packed2 = mT_packUnpackParams('pack', Settings, Unpacked2);

mT_assertStructsAreClose(Unpacked1, Unpacked2)

Packed1 = round(Packed1, 17);
Packed2 = round(Packed2, 17);

if ~isequal(Packed1, Packed2)
    disp('Error info: The following should be equal...')
    disp(Packed1)
    disp(Packed2)
    for iEntry = 1 : length(Packed1)
        disp(Packed1(iEntry))
        disp(Packed2(iEntry))
        disp(Packed2(iEntry) - Packed1(iEntry))
    end
    error('Bug')
end

end

