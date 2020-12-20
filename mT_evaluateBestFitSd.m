function Results = mT_evaluateBestFitSd(DSet, varargin)
% Estimate the standard deviation in the log-likelihood at the best fitting
% parameter values

% INPUT
% DSet: Standard data strcuture once fitting has been done.
% varargin: Cell arrary of directories as strings. These will be added to path. 
% Should contain the function(s) for comptuing the likelihood for the models 
% that have been fitted.

rng('shuffle')
nEvals = 20;

dirsToAdd = length(varargin);
if ~dirsToAdd == 0
    for iDir = 1 : dirsToAdd
        addpath(varargin{iDir})
    end
end

Results = cell(length(DSet.P), 1);

for iPtpnt = 1 : length(DSet.P)
    
    model = [1:length(DSet.P(iPtpnt).Models)]';
    estimateAtFit = NaN(length(DSet.P(iPtpnt).Models), 1);
    meanEval = NaN(length(DSet.P(iPtpnt).Models), 1);
    sdOfEvals = NaN(length(DSet.P(iPtpnt).Models), 1);
    
    for iModel = 1 : length(DSet.P(iPtpnt).Models)
        llEvals = NaN(nEvals, 1);
        
        for iEval = 1 : nEvals
            Settings = DSet.P(iPtpnt).Models(iModel).Settings;
            Params = DSet.P(iPtpnt).Models(iModel).BestFit.Params;
            
            paramVector = mT_packUnpackParams('pack', Settings, Params);
            
            llEvals(iEval) = mT_computeLL(Settings, DSet.P(iPtpnt).Data, ...
                DSet.Spec, paramVector);          
        end
        
        estimateAtFit(iModel) = DSet.P(iPtpnt).Models(iModel).BestFit.LL;
        meanEval(iModel) = mean(llEvals);
        sdOfEvals(iModel) = std(llEvals);
    end
    
    % Display results
    disp('---------------------------------------------------------')
    disp(['Participant: ' num2str(iPtpnt)])
    resultTable = table(model, estimateAtFit, meanEval, sdOfEvals);
    disp(resultTable)
    
    Results{iPtpnt} = resultTable;
    
end

if ~dirsToAdd == 0
    for iDir = 1 : dirsToAdd
        rmpath(varargin{iDir})
    end
end
            
        
        


