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

% Quit matlab if job fails
try

class(timelimit)
disp(timelimit)

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
secsLimit = (60 * 60 * str2num(timelimit(1:2))) + (60 * str2num(timelimit(4:5))) ...
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

if ~resuming
    AllResults = cell(numJobs, 1);
    completedJobs = zeros(numJobs, 1);
    jobDuration = nan(numJobs, 1);

	disp('**** New jobs ****')
else
    AllResults = LoadedVars.AllResults;
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
if (timeNow - startTime)/60 > 1.2
	disp('Exiting -- too slow')
	exit
end
            
% Add path to scripts
addpath(genpath([jobDirectory '/scripts']))

timeNow = findTimeInSecs;
disp(['System     Path added          ' ...
                num2str((timeNow - startTime)/60) ' mins.'])

% Collect required info
funNames = JobContainer.FunName;
ptpntData = JobContainer.PtpntData;
dsetSpec = JobContainer.DSetSpec;
settings = JobContainer.Settings;
setupValFuns = JobContainer.SetupValFuns;
saveFile = cell(numJobs, 1);

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
    ptpntData{iJob} = strcat(jobDirString, '/', ptpntData{iJob});
end

timeNow = findTimeInSecs;
disp(['System     Schedule start      ' ...
                num2str((timeNow - startTime)/60) ' mins.'])
            
            
% Run the jobs.
for iJob = 1 : numJobs
    avJobDuration = nanmean(jobDuration);
    if isnan(avJobDuration); avJobDuration = 0; end

    timeNow = findTimeInSecs;
    elapsedTime = timeNow - startTime;
    remainingTime = secsLimit - elapsedTime;
    disp(['Time remaining: ' num2str(remainingTime)])
    disp(['Average job duration: ' num2str(avJobDuration)])

    if completedJobs(iJob)
        % Nothing to do
    elseif avJobDuration > 100000
        disp('********** Skipping due to slow jobs **********')
    elseif (avJobDuration*2) > remainingTime
        % There is no time to do anything
        disp('Skipping jobs due to time.')
    else
        [AllResults{iJob}, completedJobs(iJob), jobDuration(iJob)] = ...
            mainEval(funNames{iJob}, ...
            ptpntData{iJob}, dsetSpec{iJob}, settings{iJob}, setupValFuns{iJob}, ...
            startTime, iJob);
    end

end

% Save reuslts if all jobs have run. Name the container after the first result.
% If not all jobs have run save the state for resuming later.
timeNow = findTimeInSecs;
disp(['System     Begin save          ' ...
                num2str((timeNow - startTime)/60) ' mins.'])

if sum(~completedJobs) == 0
    save(strcat(saveFile{1}, '_PACKED'), 'AllResults', 'saveFile')
    disp('All jobs completed')
else
    save(strcat(saveFile{1}, '_PARTIAL'), 'AllResults', 'JobContainer', ...
        'completedJobs', 'jobDuration')
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
    rmpath([jobDirectory '/bads-master'])
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

function [AllResults, completedJobs, jobDuration] = mainEval(funNames, ...
    ptpntData, dsetSpec, settings, setupValFuns, startTime, iJob)

timeNow = findTimeInSecs;
disp(['Job' num2str(iJob) '     Schedule         ' ...
    num2str((timeNow - startTime)/60) ' mins.'])
jobStart = findTimeInSecs;

AllResults = feval(funNames, ptpntData, ...
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


