function modelIdx = mT_findModelIdx(DSet, modelName)
% Find the index of a model specified by name.

% INPUT
% DSet: Data set in the standard format.
% modelName: str.

% OUTPUT
% modelIdx: The index of the requested model in DSet. I.e. the results
%   for the requested model for participant at index iP can be found at 
%   DSet.P(iP).Models(modelIdx)

appliedModels = mT_findAppliedModels(DSet);
modelIdx = find(strcmp(modelName, appliedModels));
assert(length(modelIdx) == 1)
assert(strcmp(appliedModels{modelIdx}, modelName))
assert(strcmp(DSet.P(1).Models(modelIdx).Settings.ModelName, modelName))