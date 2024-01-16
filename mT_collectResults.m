function DSet = mT_collectResults(DSet, scheduleFolder, removeStartCand,...
    allowMissing, alreadyUnpacked)
% Collects the results files after analysis on the cluster has completed

% INPUT
% DSet: This should be the dataset saved by 'mT_scheduleFits' which
% contains job ID's in places in the structure where there is a
% corresponding result file to be loaded and the reuslts added into DSet.
% scheduleFolder: Specifies the folder in which jobs and job results are stored.
% removeStartCand: boolean. Should the candidates used to select the
% starting location be retained. You may not want to retain them if you have run
% lots of fits, as they can take up a substantial proportion of memory.
% allowMissingData: boolean. If false, and there is a fit result missing an
% error is raised.
% alreadyUnpacked: boolean. Have the results from the cluster aleady been 
% upacked. If true, skips the upacking of the results files.

% HISTORY
% Reviewed 2020

if allowMissing
    excludedPtpnts = [];
end
    
if ~alreadyUnpacked
    mT_unpackResultsFiles(scheduleFolder, removeStartCand)
end

% Load the collated cluster output
LoadedFiles = load([scheduleFolder, '/', '_collectedClusterOutput']);
grandResultsCell = LoadedFiles.grandResultsCell;
grandSaveFileCell = LoadedFiles.grandSaveFileCell;

% Loop through DSet looking for all identifiers
for iPtpnt = 1 : length(DSet.P)
    for iModel = 1 : length(DSet.P(iPtpnt).Models)
        
        % Has this model been dealt with previously?
        if isfield(DSet.P(iPtpnt).Models(iModel), 'BestFit') ...
                && ~isempty(DSet.P(iPtpnt).Models(iModel).BestFit)
            
            warning('Model skipped as appears to have already been dealt with.')
            continue
        end
        
        for iStart = 1 : length(DSet.P(iPtpnt).Models(iModel).Fits)
            containerID ...
                = DSet.P(iPtpnt).Models(iModel).Fits(iStart).JobContainerID;
            subID ...
                = DSet.P(iPtpnt).Models(iModel).Fits(iStart).JobSubID;
            
            % Load the associated result file
            fileID = [containerID '_' num2str(subID) '_result'];
            match = strcmp(fileID, grandSaveFileCell);
            
            if ~any(match)
                if ~allowMissing
                    error('bug')
                elseif allowMissing
                    excludedPtpnts(end+1) = iPtpnt;
                    continue 
                end
            end
            
            if sum(match)>1; error('bug'); end
            
            % Pick out the matching data
            FitResult = grandResultsCell{match};
            
            % Store the reuslts
            mandFields = {'RngSettings', 'InitialVals', 'Params', ...
                'LL', 'SampleSize'};
            optFields = {'InitialCandidates'};
            
            for iField = 1 : length(mandFields)
                DSet.P(iPtpnt).Models(iModel).Fits(iStart).(mandFields{iField}) ...
                    = FitResult.(mandFields{iField});
            end
            
            for iField = 1 : length(optFields)
                if isfield(FitResult, optFields{iField})
                    DSet.P(iPtpnt).Models(iModel).Fits(iStart...
                        ).(optFields{iField}) ...
                        = FitResult.(optFields{iField});
                end
            end
        end
    end
end

% Exclude participants with missing analysis results
if allowMissing && ~isempty(excludedPtpnts)
    excludedPtpnts = unique(excludedPtpnts);
    DSet.P(excludedPtpnts) = [];
    warning(['Participants EXCLUDED as data not analysed yet: '])
    disp(excludedPtpnts)
end

if isempty(DSet.P)
    return
end

% Find the best fits resulting from any start point
DSet = mT_findBestFit(DSet);

% Check all paticipants have the same models applied, in the same order
mT_findAppliedModels(DSet)

end


function mT_unpackResultsFiles(directory, removeStartCand)
% Searches directory for "packed" results files (ending in _PACKED.mat), and
% unpacks them. This involves combining the cell array in each results file into
% a mega one!

packedFiles = dir([directory, '/*_PACKED.mat']);

grandResultsCell = {};
grandSaveFileCell = {};

for iFile = 1 : length(packedFiles)
    if mod(iFile, 10) == 0
        disp(['File ' num2str(iFile) '/' num2str(length(packedFiles))])
    end

    LoadedFiles = load([directory '/' packedFiles(iFile).name]);
    AllResults = LoadedFiles.AllResults;
    saveFile = LoadedFiles.saveFile;
    
    % Remove start candidates if requested
    if removeStartCand
        for iResult = 1 : length(AllResults)
            if isfield(AllResults{iResult}, 'InitialCandidates')
                AllResults{iResult}...
                    = rmfield(AllResults{iResult}, 'InitialCandidates');
            end
        end
    end
    
    % Remove function handles
    for iResult = 1 : length(AllResults)
        AllResults{iResult} = mT_removeFunctionHandles(AllResults{iResult}, ...
            {'FindSampleSize', 'FindIncludedTrials'});
    end
    
    % Remove the directory from the save file names
    for iResult = 1 : length(AllResults)
        [~, saveFile{iResult}, ~] = fileparts(saveFile{iResult});
    end
    
    grandResultsCell = [grandResultsCell; AllResults];
    grandSaveFileCell = [grandSaveFileCell; saveFile];
    
    assert(size(grandResultsCell, 2) == 1)
    assert(size(grandSaveFileCell, 2) == 1)
    assert(length(grandResultsCell) == length(grandSaveFileCell))
end

save([directory, '/', '_collectedClusterOutput'], ...
    'grandResultsCell', 'grandSaveFileCell')
    
end            