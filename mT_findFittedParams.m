function fittedParams = mT_findFittedParams(DSet, modelNum)
% Collect up the fitted parameters for a model

% INPUT
% DSet: Standard format dataset
% modelNum: Number for the model of interest, as numbered in
% DSet.P(i).Models

% OUTPUT
% fittedParams: Cell array as long as the number of participants. 
% Each cell contains a structure with fields for all the parameters, giving
% the parameter values for the corresponding participant.

% HISTORY
% 2021, JCT

fittedParams = cell(length(DSet.P), 1);

for iP = 1 : length(DSet.P)
   fittedParams{iP} = DSet.P(iP).Models(modelNum).BestFit.Params;
end


