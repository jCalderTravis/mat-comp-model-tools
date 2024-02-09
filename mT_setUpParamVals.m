function SetupVals = mT_setUpParamVals(Settings)
% Draw initial paramter values, and also produce fields descibing upper and
% lower bounds on the parameters.

% HISTORY
% Reviewed 2020

% Pick inital parameters
specs = {'InitialVals', 'LowerBound', 'PLB', 'UpperBound', 'PUB'};
optionalSpecs = {'PLB', 'PUB'};

for iSpec = 1 : length(specs)
    
    % Some of the specs are optional
    if ismember(specs{iSpec}, optionalSpecs)...
        && ~(isfield(Settings.Params, specs{iSpec}))
        warning('PLB and PUB not specified.')
        continue
    end
    
    SetupVals.(specs{iSpec}) = mT_createParamStruct(Settings, specs{iSpec});
end

end


function ParamStruct = mT_createParamStruct(Settings, field)
% Create a strcuture with a field for every parameter. The value is
% set to that specified in the requested field of 'Settings'.

% NOTE
% This functions calls the function in 'Settings.Params(iParam).(field)()'. If
% the function gives random results, the ParamStrcut produced will be
% different every run.

% INPUT
% Settings      Standard settings strcut
% field         The parameter values will be taken from calls to
%               Settings.Params(iParam).(field)()

for iParam = 1 : length(Settings.Params)

    ParamStruct.(Settings.Params(iParam).Name) = ...
        Settings.Params(iParam).(field)();     
end

end