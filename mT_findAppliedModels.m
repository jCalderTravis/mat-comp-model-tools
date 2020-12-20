function models = mT_findAppliedModels(DSet)
% Check all participants have the same models fitted, in the same order, and 
% return these models in a cell array.

% Find participant 1 models
models = {};
for iModel = 1 : length(DSet.P(1).Models)
    models{end +1} = DSet.P(1).Models(iModel).Settings.ModelName;
end


% Check other particpants have the same models in the same order
for iP = 1 : length(DSet.P)
    assert(length(models) == length(DSet.P(iP).Models))
    for iModel = 1 : length(DSet.P(iP).Models)
        assert(isequal(models{iModel}, ...
            DSet.P(iP).Models(iModel).Settings.ModelName))
    end
end
    
    