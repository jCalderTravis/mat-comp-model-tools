function AllParamBounds = mT_collectParamBounds(DSet)
% Goes through the dataset. If all models and paraiticpants are fitted with
% parameters that share upper, lower, and plausible upper and lower bounds, then
% produces a structure describing these.

% HISTORY
% Reviewed 2020

AllParamBounds = struct('LowerBound', [], 'PLB', [], 'PUB', [], 'UpperBound', []);

for iP = 1 : length(DSet.P)
    for iM = 1 : length(DSet.P(iP).Models)
        bounds = fieldnames(DSet.P(iP).Models(iM).Settings.ParamBounds);
        
        for iB = 1 : length(bounds)    
            if ~isfield(AllParamBounds, bounds{iB}); error('Bug'); end
            
            params = fieldnames(...
                DSet.P(iP).Models(iM).Settings.ParamBounds.(bounds{iB}));
            
            for iPM = 1 : length(params)
                newVal = unique(DSet.P(iP).Models(iM).Settings.ParamBounds.( ...
                        bounds{iB}).(params{iPM}));
                if length(newVal) ~= 1
                    error(['Script assumes that all sub-parameters have the ' ...
                        'same bounds.'])
                end
                
                % If we have found this parameter before, check the bounds match
                if isfield(AllParamBounds.(bounds{iB}), params{iPM})
                    storedVal = AllParamBounds.(bounds{iB}).(params{iPM});
                    if ~(storedVal == newVal)
                        error(['Script assumes same bounds applied for all ', ...
                            'participants and models, whenever the parameter is ', ...
                            'in a model.'])
                    end
                
                % If we have not found this parameter before, store the bounds
                else
                    AllParamBounds.(bounds{iB}).(params{iPM}) = newVal;      
                end
            end
        end
    end
end
                
