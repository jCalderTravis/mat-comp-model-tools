function SimParams = mT_retrieveSimParams(DSet, ptpnt)
% Find the parameters used to simulate data.

% INPUT
% ptpnt: Participant number or string. If number the parameters used for 
% the corresponding participant are retrieved. If string is 'average', the
% average parameters across participants are retrieved. If string is 'stack' 
% the parameters from all participants are stacked along the first unused 
% dimention of the array in each field of DSet.P(i).Sim.Params

% Check same parameters applied to all participants
params = fieldnames(DSet.P(1).Sim.Params);

for iP = 2 : length(DSet.P)
    if ~isequal(params, fieldnames(DSet.P(iP).Sim.Params))
        error('Bug')
    end
end    
    

if isnumeric(ptpnt)
    SimParams = DSet.P(ptpnt).Sim.Params;
    
elseif strcmp(ptpnt, 'average') || strcmp(ptpnt, 'stack') 
    
    % Loop through params averaging across participants
    for iParam = 1 : length(params)
        allPtpntParams = mT_stackData( ...
            DSet.P, @(struc) struc.Sim.Params.(params{iParam}));
        
        % mT_stackData stacks along the first unused dimention greater than 1
        finalDimention = length(size(allPtpntParams));
        if size(allPtpntParams, finalDimention) ~= length(DSet.P)
            error('Bug')
        end
        
        % Average along the stack dimention (across participants) if requested
        if strcmp(ptpnt, 'stack')
            SimParams.(params{iParam}) = allPtpntParams;
        elseif strcmp(ptpnt, 'average')
            SimParams.(params{iParam}) = mean(allPtpntParams, finalDimention);
        end
    end
else
    error('Unknown option')
end

