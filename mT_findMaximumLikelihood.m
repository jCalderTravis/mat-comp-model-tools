function [Result, Logs] = mT_findMaximumLikelihood(PtpntData, DSetSpec, Settings, ...
    SetupValFun, jobNum)
% Find the maximum likelihood fit (at the participant level) for the the model
% specified in settings.

% INPUT
% PtpntData     DSet.P(iPtpnt).Data from the standard data structure, or name of
%               file to load that contains this data in a variable called
%               PtpntData.
% DSetSpec      DSet.Spec from the standard data structure, or file
%               name to load containting this data in a variable called
%               DSetSpec.
% Settings      See README. Similarly to PtpntData, and DSetSpec, may be a
%               filename.
% SetupValFun         Function handle. Function is passed the Settings structure,
%                     and should produce an a unpacked param
%                     structure of the form produced by mT_setUpParamVals. If
%                     requested the function will be called multiple times, the
%                     LL evaluated at the resulting points, and the
%                     best one used as the start point for the optimiser.

% OUTPUT
% Result       Results of the fitting.
% Logs         Structure detailing the various initial candedate parameter 
%              values, and their associated negative log-liklihoods.

funTimer = tic;

% Load variables that are saved seperately.
if isstring(PtpntData)
    LoadedVars = load(PtpntData);
    PtpntData = LoadedVars.PtpntData;
end

if isstring(DSetSpec)
    LoadedVars = load(DSetSpec);
    DSetSpec = LoadedVars.DSetSpec;
end

if isstring(Settings)
    LoadedVars = load(Settings);
    Settings = LoadedVars.TheseSettings;
end

disp(['Job' num2str(jobNum) '     Vars loaded      '   num2str(toc(funTimer)) ' secs.'])

Result.RngSettings = rng;
if isfield(Settings, 'ReseedRng') && (~Settings.ReseedRng)
    error('Option to not reseed the random generator has been removed')
    % Reseeding takes place in mT_runOnCluster
end


% Define the objective function is *negative* LL
objectiveFun = @(paramVector) -mT_computeLL(Settings, PtpntData, ...
    DSetSpec, paramVector);

% Evaluate the LL at each candidate start point
negLL = NaN(Settings.NumStartCand, 1);
AllCandValsUnpacked = cell(Settings.NumStartCand, 1);
AllCandInitialVals = NaN(Settings.NumStartCand, Settings.NumParams);

for iCand = 1 : Settings.NumStartCand
    % Convert initial params from a strcuture of parameters to a vector
    AllCandValsUnpacked{iCand} = SetupValFun(Settings);
    CandVals = packParamsAndBounds(AllCandValsUnpacked{iCand}, Settings);
    AllCandInitialVals(iCand, :) = CandVals.InitialVals;
    
    negLL(iCand) = objectiveFun(CandVals.InitialVals);
end

if any(negLL < 0); error('bug'); end

disp(['Job' num2str(jobNum) '     Starts eval''d    ' num2str(toc(funTimer)) ' secs.'])

% Save the start candidates
Logs.AllCandInitialVals = AllCandInitialVals;
Logs.NegLL = negLL;

[minNegLL, bestCand] = min(negLL);
assert(~isinf(minNegLL))
SetupValsRaw = AllCandValsUnpacked{bestCand};

% Store the initial parameter values
Result.InitialVals = SetupValsRaw.InitialVals;

% Unit test on pack/unpack function
mT_packUnpackParams('packTest', Settings, SetupValsRaw.InitialVals);

% Convert initial params from a strcuture of parameters to a vector
SetupVals = packParamsAndBounds(SetupValsRaw, Settings);

% Have we got plausible bounds
if isfield(SetupVals, 'PLB')
    plb = SetupVals.PLB;
    pub = SetupVals.PUB;
else
    plb = [];
    pub = [];
end

disp(['Job' num2str(jobNum) '     Optim start    ' num2str(toc(funTimer)) ' secs.'])

if num2str(toc(funTimer)) > 90
    disp(['Job ' num2str(jobNum) ' ****Exit candidate****'])
    if num2str(jobNum) <= 16
        exit
    end
end

% Print some info
disp('****** Info on fit')
disp('Unpacked lower bound: ')
disp(SetupValsRaw.LowerBound)
disp('Unpacked initial vals: ')
disp(SetupValsRaw.InitialVals)
disp('Unpacked upper bound: ')
disp(SetupValsRaw.UpperBound)

disp(['Packed lower bound: ' num2str(SetupVals.LowerBound)])
disp(['Packed initial vals: ' num2str(SetupVals.InitialVals)])
disp(['Packed upper bound: ' num2str(SetupVals.UpperBound)])
disp('******')

% Time to minimise. Are there boundary constriaints?
if strcmp(Settings.FindIfOutOfBounds, 'none')
    
    % Which algorithm to use
    if strcmp(Settings.Algorithm, 'bads')
        
        [fittedParams, negativeLL] = ...
            bads(objectiveFun, SetupVals.InitialVals, ...
            SetupVals.LowerBound, SetupVals.UpperBound, ...
            plb, pub);
        
    elseif strcmp(Settings.Algorithm, 'fmincon')
        
        if Settings.DebugMode
            options = optimoptions('fmincon', ...
                'MaxFunctionEvaluations', 3, ...
                'MaxIterations', 3);
        else
            options = optimoptions('fmincon', ...
                'MaxFunctionEvaluations', 40000, ...
                'MaxIterations', 10000, ...
                'StepTolerance', (10^(-40)), ...
                'FiniteDifferenceType', 'central');
        end
        
        [fittedParams, negativeLL] = ...
            fmincon(objectiveFun, SetupVals.InitialVals, ...
            [], [], [], [], ...
            SetupVals.LowerBound, ...
            SetupVals.UpperBound, ...
            [], options);
    end
else
    error('No longer used')
end

% Code checks
if any(isnan(fittedParams))
    error(['Bug. ' ...
        'Warning: If remove this check ' ...
        'calculation of BIC and AIC may be incorrect.'])
end
if length(fittedParams) ~= Settings.NumParams; error('Bug'); end

% Store the fitted params and LL
Result.Params = ...
    mT_packUnpackParams('unpack', Settings, fittedParams);
Result.LL = -negativeLL;

% Store some extra info about the fit
Result.SampleSize = Settings.FindSampleSize(PtpntData);

% Code checks
if sum(Settings.FindIncludedTrials(PtpntData)) ...
        ~= Settings.FindSampleSize(PtpntData)
    error('Bug')
end

disp(['Job' num2str(jobNum) '     Optim end        ' num2str(toc(funTimer)) ' secs.'])

end


function SetupVals = packParamsAndBounds(SetupValsRaw, Settings)
% Convert initial params from a strcuture of parameters to a vector

specs = {'InitialVals', 'LowerBound', 'PLB', 'UpperBound', 'PUB'};
optionalSpecs = {'PLB', 'PUB'};

for iSpec = 1 : length(specs)    
    % Some of the specs are optional
    if ismember(specs{iSpec}, optionalSpecs) ...
            && ~(isfield(SetupValsRaw, specs{iSpec}))
        continue
    end
    
    SetupVals.(specs{iSpec}) = ...
        mT_packUnpackParams('pack', Settings, SetupValsRaw.(specs{iSpec}));
end

end








