function paramMedian = mT_produceParamStats(DSet, dir, varargin)
% Produce statistics on the fitted paramters accross participants.

% INPUT
% dir: Where to save the results file (ready for latex). Set to 'none' if don't
% want to save
% varargin 1: Vector if want params for some models only, or leave empty.
% varargin 2: Text to use for the labeling the parameters. Structure with a
% field for every paramter want to relable. Field contains text.
% varargin 3: Text to add to the file name when saving
% varargin 4: numModels long cell array of model names to use instead of 
% simply numebering the models. Needs to be as long as the number of models
% that have fit results in DSet, not just as long as the number of model 
% for which paramter values have been requested.

% NOTE
% For use in latex, need to have the package siunitx

models = mT_findAppliedModels(DSet);

if ~isempty(varargin) && ~isempty(varargin{1})
    modelsToAnlyse = varargin{1};
else
    modelsToAnlyse = 1 : length(models);
end

if (length(varargin)>=2) && ~isempty(varargin{2})
    ParamLabels = varargin{2};
else
    ParamLabels = struct();
end

if length(varargin)>=3 && ~isempty(varargin{3})
    fileNameEnd = varargin{3};
else
    fileNameEnd = '';
end

if length(varargin)>=4 && ~isempty(varargin{4})
    modelNames = varargin{4};
    if length(modelNames) ~= length(models)
        error(['modelNames needs to be as long as the number of models ', ...
                'that have fit results in DSet, not just as long as the ', ...
                'number of model for which paramter values have been ', ...
                'requested.'])
    end
else
    modelNames = [];
end

% Open a file to write results to, and add titles
if ~strcmp(dir, 'none')
    saveFile = fopen([dir '/paramStats' fileNameEnd '.tex'], 'w' );
    
    fprintf(saveFile, '%s\n', '\begin{table}[H]');
    fprintf(saveFile, '%s\n', '\begin{center}');
    fprintf(saveFile, '%s\n', '\renewcommand{\arraystretch}{1.29}');
    fprintf(saveFile, '%s\n', '\begin{tabular}{l l l l l |}');
    fprintf(saveFile, '%s\n', 'Model & Parameter & Median & 25th percentile & 75th percentile \\');
    fprintf(saveFile, '%s\n', '\toprule');
end 

for iModel = modelsToAnlyse
    if ~isempty(modelNames)
        thisModelName = modelNames{iModel};
    else
        thisModelName = num2str(iModel);
    end
    
    % Find the parameters in this model
    params = fieldnames(DSet.P(1).Models(iModel).BestFit.Params);
    
    % Find out how many subparams each parameter has
    subParamTot = NaN(length(params), 1);
    
    for iParam = 1 : length(subParamTot)
        subParamTot(iParam) = length(...
            DSet.P(1).Models(iModel).BestFit.Params.(params{iParam})(:));
    end
    
    paramNames = {};
    paramMedian = [];
    paramIqr = []; % Interquartile range
    Pcent25 = [];
    Pcent75 = [];
    paramCount = 1;
    
    for iParam = 1 : length(params)
        
        if isfield(ParamLabels, params{iParam})
            label = ParamLabels.(params{iParam});
        else
            label = params{iParam};
        end
        
        subParams = subParamTot(iParam);
        for iSubParam = 1 : subParams
            
            % Find data for the print out
            if iParam == 1 && iSubParam == 1
                if iModel == modelsToAnlyse(1)
                    midline = '';
                else
                    midline = '\\midrule';
                end
                
                modelText = [midline ' \n \\multirow{%d}{*}{%s} &'];
                modelArgs = {sum(subParamTot), thisModelName};
            else
                modelText = ' &';
                modelArgs = {};
            end
            
            if iSubParam == 1
                paramText = ' \\multirow{%d}{*}{%s} &';
                paramArgs = {subParamTot(iParam), label};
            else
                paramText = ' &';
                paramArgs = {};
            end
            
            paramVals = mT_stackData(DSet.P, ...
                @(st) st.Models(iModel).BestFit.Params.(params{iParam} ...
                )(iSubParam));
            
            paramNames{paramCount, 1} = params{iParam};
            paramMedian(paramCount, 1) = median(paramVals);
            paramIqr(paramCount, 1) = iqr(paramVals);
            Pcent25(paramCount, 1) = prctile(paramVals,25);
            Pcent75(paramCount, 1) = prctile(paramVals,75);
            
            % Print output
            if ~strcmp(dir, 'none')
                fprintf(saveFile, [modelText, paramText, ...
                    ' \\num[round-precision=2,round-mode=figures]{%f}', ...
                    ' & \\num[round-precision=2,round-mode=figures]{%f}', ...
                    ' & \\num[round-precision=2,round-mode=figures]{%f}\\\\ \n'], ...
                    modelArgs{:}, paramArgs{:}, ...
                    paramMedian(paramCount), ...
                    Pcent25(paramCount), Pcent75(paramCount));
            end
            
            paramCount = paramCount +1;
            
            if ~strcmp(dir, 'none')
                if iSubParam == subParams && ~(iParam == length(params))
                    fprintf(saveFile, '%s \n', '\cline{2-5}');
                end
            end
        end
    end
    
    % Display results
    disp('**********************')
    disp(['Model: ' num2str(iModel)])
    resultTable = table(paramNames, paramMedian, paramIqr, Pcent25, Pcent75);
    disp(resultTable)
    
end

if ~strcmp(dir, 'none')
    fprintf(saveFile, '%s\n', '\bottomrule');
    fprintf(saveFile, '%s\n', '\end{tabular}');
    fprintf(saveFile, '%s\n', '\end{center}');
    fprintf(saveFile, '%s\n', '\end{table}');
    fclose(saveFile);
end


