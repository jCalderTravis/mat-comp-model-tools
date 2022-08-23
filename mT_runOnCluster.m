function mT_runOnCluster(jobDirectory, jobFile, resuming, timelimit, varargin)
% Loads and runs the jobs in jobFile. All relevant MATLAB scripts should be in 
% the folder jobDirectory/scripts or subfolders of this folder.

% NOTE
% The phrase 'job' should not appear anywhere in the directory of the job
% file, except in the filename itself. Otherwise an error is tirggered.

% INPUT
% resuming: String, "0" or "1". Are we resuming from a fit which was previously
% stopped due to timeout?
% timelimit: After this time the program will stop and results so far saved. 
% Specified in the format used by slurm.
% varargin: If set to 'debug', MATLAB does not quit on error

disp('Key input arguments...')
disp(['jobDirectory: ' jobDirectory '; of type ' class(jobDirectory)])
disp(['jobFile: ' jobFile '; of type ' class(jobFile)])
disp(['resuming: ' resuming '; of type ' class(resuming)])
disp(['timelimit: ' timelimit '; of type ' class(timelimit)])

% Quit matlab if job fails
try
    
addpath(genpath([jobDirectory '/scripts']))

% Process resuming input
disp(str2num(resuming))
if str2num(resuming)
    resuming = true;
else
    resuming = false;
end
    
% Process time limit info
disp(['Submision time limit: ' timelimit])
if length(timelimit) ~= 8; error('Unexpected time spec'); end 
secsLimit = (60 * 60 * str2num(timelimit(1:2))) ...
    + (60 * str2num(timelimit(4:5))) ...
    + str2num(timelimit(7:8));
disp(['... in seconds: ' num2str(secsLimit)])
startTime = findTimeInSecs;

timeNow = findTimeInSecs;
disp(['System     Timing setup        ' ...
                num2str((timeNow - startTime)/60) ' mins.'])
            
if ~isempty(varargin) && strcmp(varargin{1}, 'debug')
    inDebugMode = true;
    disp('System     Debug mode ON')
else
    inDebugMode = false;
    disp('System     Debug mode OFF')
end

% Load data
LoadedVars = load(jobFile);
JobContainer = LoadedVars.JobContainer;
numJobs = sum(~isnan(JobContainer.JobSubID));

% Set random seed in such a way that it is unique for each job, and also
% within a job, for each time that job is restarted
rng('shuffle')
randomSeed = randi(100000) + JobContainer.Count;
rng(randomSeed)
disp(['Random generator seed used: ' num2str(randomSeed)])

if ~resuming
    AllResults = cell(numJobs, 1);
    AllLogs = cell(numJobs, 1);
    completedJobs = zeros(numJobs, 1);
    jobDuration = nan(numJobs, 1);

	disp('**** New jobs ****')
else
    AllResults = LoadedVars.AllResults;
    AllLogs = LoadedVars.AllLogs;
    completedJobs = LoadedVars.completedJobs;
    jobDuration = LoadedVars.jobDuration;

	disp(['Previous average job duration: ' num2str(nanmean(jobDuration))])
	jobDuration = nan(size(jobDuration));

	disp('**** Resuming jobs ****')
end

timeNow = findTimeInSecs;
disp(['System     Data loaded         ' ...
                num2str((timeNow - startTime)/60) ' mins.'])
            
% Are things going very slowly?
if (timeNow - startTime)/60 > 5
	disp('Exiting -- too slow')
	exit
end
            
% Collect required info
funNames = JobContainer.FunName;
ptpntData = JobContainer.PtpntData;
dsetSpec = JobContainer.DSetSpec;
settings = JobContainer.Settings;
setupValFuns = JobContainer.SetupValFuns;
saveFile = cell(numJobs, 1);
logsSaveFile = cell(numJobs, 1);

timeNow = findTimeInSecs;
disp(['System     Collected info      ' ...
                num2str((timeNow - startTime)/60) ' mins.'])

% Work out where we are on the current system, and replace the old schedule
% folder in the file paths for ptpntData, DSetSpec, and settings, with the
% current one. Specify where to save result of analysis.
jobDirString = convertCharsToStrings(jobDirectory);

if resuming; trim = 20;
else; trim = 7; 
end

for iJob = 1 : numJobs
    saveFile{iJob} = [jobFile(1 : end-trim), ...
        num2str(JobContainer.JobSubID(iJob)) '_result'];
    logsSaveFile{iJob} = [jobFile(1 : end-trim), ...
        num2str(JobContainer.JobSubID(iJob)) '___logs'];
    ptpntData{iJob} = strcat(jobDirString, '/', ptpntData{iJob});
end

timeNow = findTimeInSecs;
disp(['System     Schedule start      ' ...
                num2str((timeNow - startTime)/60) ' mins.'])
            
            
% Run the jobs.
if ~JobContainer.UseParfor
    disp('Not using parfor')
    
    for iJob = 1 : numJobs
        [avJobDuration, remainingTime] = findKeyTimes(jobDuration, ...
            startTime, secsLimit);

        if completedJobs(iJob)
            % Nothing to do
        elseif avJobDuration > 100000
            disp('********** Skipping due to slow jobs **********')
        elseif (avJobDuration*2) > remainingTime
            % There is no time to do anything
            disp('Skipping jobs due to time.')
        else
            [AllResults{iJob}, AllLogs{iJob}, completedJobs(iJob), ...
                jobDuration(iJob)] = ...
                    mainEval(funNames{iJob}, ptpntData{iJob}, ...
                        dsetSpec{iJob}, settings{iJob}, ...
                        setupValFuns{iJob}, startTime, iJob);
        end

    end
else
    batchSize = 128;
    disp(['Using parfor with batch size ' num2str(batchSize)])
    
    % Find number of parallel pool workers
    try
        pool = gcp('nocreate');
        if isempty(pool)
            numWorkers = 1;
            disp('Could not find parallel pool')
        else
            numWorkers = pool.NumWorkers;
            disp(['Found ' num2str(numWorkers) ' workers.'])
        end
    catch
        numWorkers = 1;
        disp('Error looking for parallel pool')
    end
    
    numBatches = ceil(numJobs / batchSize);
    for iBatch = 1 : numBatches
        thisBatchStart = 1 + ((iBatch-1) * batchSize);
        thisBatchEnd = iBatch * batchSize;
        if thisBatchEnd > numJobs
            assert(iBatch == numBatches)
            thisBatchEnd = numJobs;
        end
        
        % Should we begin another parfor loop, or should we save the work
        % so far and stop, due to time
        [avJobDuration, remainingTime] = findKeyTimes(jobDuration, ...
            startTime, secsLimit);
        estBatchDuration = avJobDuration * ...
            (thisBatchEnd - thisBatchStart + 1) / numWorkers;
        disp(['Estimated duration of one batch: ' ...
            num2str(estBatchDuration)])
        
        if (estBatchDuration*2) > remainingTime
            disp(['Skipping batch ' num2str(iBatch) ' due to time.'])
            continue
        else
            disp(['Starting batch ' num2str(iBatch) '.'])
        end
        
        parfor iJob = thisBatchStart : thisBatchEnd            
            if completedJobs(iJob)
                % Nothing to do
            else
                [AllResults{iJob}, AllLogs{iJob}, ...
                    completedJobs(iJob), jobDuration(iJob)] = ...
                        mainEval(funNames{iJob}, ptpntData{iJob}, ...
                        dsetSpec{iJob}, settings{iJob}, ...
                        setupValFuns{iJob}, startTime, iJob);
            end
        end
    end
end

% Save reuslts if all jobs have run. Name the container after the first result.
% If not all jobs have run save the state for resuming later.
timeNow = findTimeInSecs;
disp(['System     Begin save          ' ...
                num2str((timeNow - startTime)/60) ' mins.'])

if sum(~completedJobs) == 0
    save(strcat(saveFile{1}, '_PACKED'), 'AllResults', 'saveFile')
    save(strcat(logsSaveFile{1}, '_PACKED'), 'AllLogs')
    disp('All jobs completed')
else
    save(strcat(saveFile{1}, '_PARTIAL'), 'AllResults', 'JobContainer', ...
        'completedJobs', 'jobDuration', 'AllLogs')
    disp(['Saved after ' num2str(sum(completedJobs)) ' of ' ...
        num2str(length(completedJobs)) ' jobs completed.'])
end

timeNow = findTimeInSecs;
disp(['System     Save complete       ' ...
                num2str((timeNow - startTime)/60) ' mins.'])


% Quit unless in debug mode
if ~inDebugMode
	disp('Exiting normally')
    exit
else
    % Don't want these if keeping MATLAB open
    rmpath(genpath([jobDirectory '/scripts']))
end

catch erMsg
     disp(erMsg)
     for i = 1 : length(erMsg.stack)
         disp(erMsg.stack(i))
     end
     
     % Quit unless in debug mode
     if ~inDebugMode
        disp('Exiting after crash')
         exit
     end
end

disp('Failed to exit')

end


function startTime = findTimeInSecs

datetimeNow = clock;
startTime = (datetimeNow(3) *(24*60*60)) + ...
    (datetimeNow(4) *(60*60)) + ...
    (datetimeNow(5) *(60)) + ...
    (datetimeNow(6));

end


function [avJobDuration, remainingTime] = findKeyTimes(jobDuration, ...
    startTime, secsLimit)

avJobDuration = nanmean(jobDuration);
if isnan(avJobDuration); avJobDuration = 0; end

timeNow = findTimeInSecs;
elapsedTime = timeNow - startTime;
remainingTime = secsLimit - elapsedTime;
disp(['Time remaining: ' num2str(remainingTime)])
disp(['Average job duration: ' num2str(avJobDuration)])

end


function [AllResults, Logs, completedJobs, jobDuration] = mainEval(funNames, ...
    ptpntData, dsetSpec, settings, setupValFuns, startTime, iJob)

timeNow = findTimeInSecs;
disp(['Job' num2str(iJob) '     Schedule         ' ...
    num2str((timeNow - startTime)/60) ' mins.'])
jobStart = findTimeInSecs;

[AllResults, Logs] = feval(funNames, ptpntData, ...
    dsetSpec, settings, setupValFuns, iJob);

timeNow = findTimeInSecs;
disp(['Job' num2str(iJob) '     Removing Handles ' ...
    num2str((timeNow - startTime)/60) ' mins.'])

AllResults = mT_removeFunctionHandles(AllResults, {'FindSampleSize', ...
    'FindIncludedTrials'});

timeNow = findTimeInSecs;
disp(['Job' num2str(iJob) '     Removed Handles  ' ...
    num2str((timeNow - startTime)/60) ' mins.'])

completedJobs = 1;
jobDuration = findTimeInSecs - jobStart;

end


