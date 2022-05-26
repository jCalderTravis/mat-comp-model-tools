function DSet = mT_scheduleFits(mode, DSet, Settings, scheduleFolder)

% INPUT
% mode          str. 'cluster' schedules for the cluster without a parfor 
%               loop, 'clusterPar' schedules for the cluster with a parfor
%               loop used on the cluster, and 'local' runs immediately
% DSet          Should follow the standard data format. See README.
% Settings      Structure. See README. If Settings
%               is an array of such structures, a fit is scheduled for each
%               strcuture. (One structure describes one model.)
% scheduleFolder    
%               Only used in 'cluster' mode. Specifies the folder in
%               which to store schedued jobs.

% OUTPUT
% DSet      Results of modelling are stored in DSet.P(i).Models, unless this 
%           already exists, in which case 'Models' becomes a struct array and 
%           the current results are placed in the first free space.

jobsPerContainer = Settings.JobsPerContainer;

for iSet = 1 : length(Settings)
    if isfield(Settings(iSet), 'ReseedRng') && (~Settings(iSet).ReseedRng)
        error('Option to not reseed the random generator has been removed')
        % Reseeding takes place in mT_runOnCluster
    end
end

if strcmp(mode, 'local')
    % Reseeding takes place in mT_runOnCluster when running on cluster
    rng('shuffle')
end

% Work out where we will store the results of the modelling? This depends
% of how many different models have been applied previously.
if ~isfield(DSet.P(1), 'Models'); prevModels = 0;
else; prevModels = length(DSet.P(1).Models); end

% Check that all participants have had the same models applied previously
if isfield(DSet.P, 'Models')
    mT_findAppliedModels(DSet);
end


% Save participant data for later use if running on cluster
PtpntDataSaveDir = cell(length(DSet.P), 1);

if any(strcmp(mode, {'cluster', 'clusterPar'}))
    for iPtpnt = 1 : length(DSet.P)
        PtpntData = DSet.P(iPtpnt).Data;
        PtpntDataSaveDir{iPtpnt} = tempname(scheduleFolder);
        PtpntData = mT_removeFunctionHandles(PtpntData, ...
            {'FindSampleSize', 'FindIncludedTrials'});
        save(PtpntDataSaveDir{iPtpnt}, 'PtpntData')
        
        % Check the save
        saveFile = dir([PtpntDataSaveDir{iPtpnt}, '.mat']);         
        fileSize = saveFile.bytes;
        if ~(fileSize > 10000); error('Bug'); end
    end
else
    assert(strcmp(mode, 'local'))
end


% If we will be running on the cluster we need to store the requested
% function runs for later execution.
if any(strcmp(mode, {'cluster', 'clusterPar'}))
    funNum = 1;
    jobContainerCount = 1;
    JobContainer = generateJobContainer(jobsPerContainer, jobContainerCount, ...
        scheduleFolder, mode);
else
    assert(strcmp(mode, 'local'))
end

for iModel = 1 : length(Settings)
    TheseSettings = Settings(iModel);
    
    for iPtpnt = 1 : length(DSet.P)
        % Store the settings used for modelling below
        DSet.P(iPtpnt).Models(prevModels + iModel).Settings = TheseSettings;
        
        BoundaryVals = mT_setUpParamVals(TheseSettings);
        BoundaryVals = rmfield(BoundaryVals, 'InitialVals');
        DSet.P(iPtpnt).Models(prevModels + iModel).Settings.ParamBounds ...
            = BoundaryVals;
        
        % If requested in 'TheseSettings', run the minimisation several times from
        % different start points.
        for iStartPoint = 1 : TheseSettings.NumStartPoints
            
            % Are we using the end points from previous fits as start points, or
            % drawing new ones?
            if ~TheseSettings.PresetStartPoints
                SetupValsFun = @(Settings) mT_setUpParamVals(Settings);
                
            elseif TheseSettings.PresetStartPoints
                SetupVals = mT_setUpParamVals(TheseSettings);
                SetupVals.InitialVals ...
                    = DSet.P(iPtpnt).Models(iModel).Fits(iStartPoint).Params;
                SetupValsFun = @(Settings) SetupVals;
                
            end
            
            DSetSpec = DSet.Spec;
            
            if strcmp(mode, 'local')
                % If we are on the local machine we wont have saved the participant
                % data for later loading, instead we need to find it now.
                PtpntData = DSet.P(iPtpnt).Data;

                [DSet.P(iPtpnt).Models(prevModels + iModel).Fits(iStartPoint), ...
                    ~] = mT_findMaximumLikelihood(PtpntData, DSetSpec, ...
                    TheseSettings, SetupValsFun, '--');
                
            elseif any(strcmp(mode, {'cluster', 'clusterPar'}))
                
                JobContainer.JobSubID(funNum) = funNum;
                JobContainer.FunName{funNum} = 'mT_findMaximumLikelihood';
                
                % Save the filenames of relevant files as strings
                PtpntDataSaveDir{iPtpnt} = convertCharsToStrings(PtpntDataSaveDir{iPtpnt});
                [~, PtpntDataSaveFile, ~] = fileparts(PtpntDataSaveDir{iPtpnt});
                
                JobContainer.PtpntData{funNum} = PtpntDataSaveFile;
                JobContainer.DSetSpec{funNum} = DSetSpec;
                JobContainer.Settings{funNum} = TheseSettings;
                JobContainer.SetupValFuns{funNum} = SetupValsFun;
                
                % Store the ID number in the corresponding location in DSet
                DSet.P(iPtpnt).Models(prevModels + iModel).Fits(iStartPoint).JobContainerID ...
                    = JobContainer.ID;
                DSet.P(iPtpnt).Models(prevModels + iModel).Fits(iStartPoint).JobSubID ...
                    = JobContainer.JobSubID(funNum);
                
                funNum = funNum +1;
                
                % Have we filled the job container?
                if funNum > jobsPerContainer
                    
                    % Save the JobContainer ready for execution later. First
                    % remove function handles in places we don't need them.
                    saveWithoutSomeHandles(JobContainer)
                    
                    % Set up a new job container
                    funNum = 1;
                    jobContainerCount = jobContainerCount +1;
                    JobContainer = generateJobContainer(jobsPerContainer, ...
                        jobContainerCount, ...
                        scheduleFolder, ...
                        mode);
                end
            else
                error('Bug')
            end
        end
        disp('One participant, one model, complete')
    end
end

% Save the final job container
if any(strcmp(mode, {'cluster', 'clusterPar'})) && ~(funNum == 1)
    saveWithoutSomeHandles(JobContainer)
end

% If we are running in local mode then during the execution of this script
% we will have already fit all models, so we can do some extra analysis
% with these results, and find the best fit resulting from any start point.
if strcmp(mode, 'local') 
    DSet = mT_findBestFit(DSet);    
end

% If we are running in cluster mode save DSet, as this now contains job IDs
% which link to the scheduled jobs.
if any(strcmp(mode, {'cluster', 'clusterPar'}))
    now = string(datetime);
    now = now{1};
    now([3, 7, 15, 18]) = [];
    
    tic
    DSet = mT_removeFunctionHandles(DSet, {'FindSampleSize', 'FindIncludedTrials'});
    save([scheduleFolder '/_' now '_DataStruct'], 'DSet', '-v7.3')
    diff = toc;
    
    % If saving the files has been particularly quick, wait 3 seconds to ensure
    % that if this function is called again immediately, no JobContainers will
    % be given the same name as an existing one (these are based on the time in
    % seconds).
    if diff < 3; pause(3); end
    
end

end


function JobContainer = generateJobContainer(jobsPerContainer, ...
    jobContainerCount, scheduleFolder, mode)
% Generate a strcuture to store requested jobs

% Generate a job ID number 
now = string(datetime);
now = now{1};
now([3, 7, 15, 18]) = [];
now(10)='_';

jobContainerID = [now '_' num2str(jobContainerCount)];
JobContainer.Count = jobContainerCount;
JobContainer.ID = jobContainerID;

% Where will we save the job container later?
JobContainer.SaveDir = [scheduleFolder '/' JobContainer.ID '_job.mat'];

% Check this file doesn't already exist
if isfile(JobContainer.SaveDir)
    error('bug')
end

JobContainer.JobSubID  = NaN(jobsPerContainer, 1);

if strcmp(mode, 'cluster')
    JobContainer.UseParfor = false;
elseif strcmp(mode, 'clusterPar')
    JobContainer.UseParfor = true;
else
    error('Bug')
end

end

function saveWithoutSomeHandles(JobContainer)

ContainerWithHandles = JobContainer;
JobContainer = mT_removeFunctionHandles(JobContainer, ...
    {'FindSampleSize', 'FindIncludedTrials'});
JobContainer.Settings = ContainerWithHandles.Settings;
JobContainer.SetupValFuns = ContainerWithHandles.SetupValFuns;

save(JobContainer.SaveDir, 'JobContainer')

end

    
    
    