function LL = mT_computeLL(Settings, PtpntData, DSetSpec, paramVector)
% Computes the loglikelihood for a participant

% TODO
% We often have two copies of FindIndludedTrials. The one in Settings,
% and the one passed to feval in Settings.ComputeTrialLL.Args.
% Solution: Always pass find included trials to feval?

if ~Settings.SuppressOutput
    tic
end

if ischar(Settings.FindSampleSize)
    findSampleSize = str2func(Settings.FindSampleSize);
    sampleSize = findSampleSize(PtpntData);
else
    sampleSize = Settings.FindSampleSize(PtpntData);
end

% Unpack the parameter vector
ParamStruct = mT_packUnpackParams('unpack', Settings, paramVector);


% Are we applying a regulariser?
regulariserEffect = 0;

if isfield(Settings.Params, 'Regulariser')
    params = fieldnames(ParamStruct);
    assert(length(params) == length(Settings.Params))
    
    for iParam = 1 : length(params)
        if isstring(Settings.Params(iParam).Regulariser)
            Settings.Params(iParam).Regulariser ...
                = str2func(Settings.Params(iParam).Regulariser);
        end
        
       regulariserEffect = regulariserEffect + ...
           Settings.Params(iParam).Regulariser(ParamStruct.(params{iParam}));
    end
end


% Initialise
trialLLs = NaN(sampleSize, 1);

% Are we going to chunk the trials?
if ~strcmp(Settings.TrialChunkSize, 'off')
    error('No longer used')
    
% Otherwsie we are not doing chunking. Just pass all data.
else
    % Time to do the actual computations!
    trialLLs = feval(Settings.ComputeTrialLL.FunName, ...
            Settings.ComputeTrialLL.Args{:}, ParamStruct, PtpntData, DSetSpec);
end

% Sum the LL, excluding trials if requested
if ischar(Settings.FindIncludedTrials)
    findIncludedTrials = str2func(Settings.FindIncludedTrials);
    includedTrials = findIncludedTrials(PtpntData);
else
    includedTrials = Settings.FindIncludedTrials(PtpntData);
end

if strcmp(includedTrials, 'all')
    LL = sum(trialLLs);
else
    LL = sum(trialLLs(includedTrials));
end

if any(trialLLs(includedTrials) > 0)
    error('Bug')
end

if ~Settings.SuppressOutput
    disp('1 pass')
    toc
end

if isnan(LL) || LL > 0
    error('Bug')
end

assert(sampleSize == sum(includedTrials))

% Apply regulariser
LL = LL + regulariserEffect;

end