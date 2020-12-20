function mT_produceParamBoundsTable(AllParamBounds, dir, varargin)
% Produce statistics on the fitted paramters accross participants.

% INPUT
% AllParamBounds: Produced by the function mT_collectParamBounds
% dir: Where to save the results file (ready for latex)
% varargin{1} : Text to use for the labeling the parameters. Structure with a
% field for every paramter want to relable. Field contains text.
% varargin{2}: Ending to add to the filename

% NOTE
% For use in latex, need to have the package siunitx

if length(varargin)>=1 && ~isempty(varargin{1})
    ParamLabels = varargin{1};
else
    ParamLabels = struct();
end

if length(varargin)>=2 && ~isempty(varargin{2})
    fileNameEnd = varargin{2};
else
    fileNameEnd = '';
end

% Open a file to write results to, and add table titles
saveFile = fopen([dir '/paramBounds' fileNameEnd '.tex'], 'w' );

fprintf(saveFile, '%s\n', '\begin{table}[H]');
fprintf(saveFile, '%s\n', '\begin{center}');
fprintf(saveFile, '%s\n', '\renewcommand{\arraystretch}{1.29}');
fprintf(saveFile, '%s\n', '\begin{tabular}{l l l l l |}');
fprintf(saveFile, '%s\n', ['Parameter & Lower bound & Plausible lower bound & '...
    'Plausible upper bound & Upper bound \\']);
fprintf(saveFile, '%s\n', '\toprule');
    
params = fieldnames(AllParamBounds.LowerBound);
for iPM = 1 : length(params)
    
    LowerBound = AllParamBounds.LowerBound.(params{iPM});
    PLB = AllParamBounds.PLB.(params{iPM});
    PUB = AllParamBounds.PUB.(params{iPM});
    UpperBound = AllParamBounds.UpperBound.(params{iPM});
    
    if isfield(ParamLabels, params{iPM})
        label = ParamLabels.(params{iPM});
    else
        label = params{iPM};
    end
    
    % Print output
    [formatLowerBound, entryLowerBound] = findFormatAndEntry(LowerBound);
    [formatPLB, entryPLB] = findFormatAndEntry(PLB);
    [formatPUB, entryPUB] = findFormatAndEntry(PUB);
    [formatUpperBound, entryUpperBound] = findFormatAndEntry(UpperBound);
    
    fprintf(saveFile, ['%s', ...
        formatLowerBound, ...
        formatPLB, ...
        formatPUB, ...
        formatUpperBound, '\\\\ \n'], ...
        label, entryLowerBound, entryPLB, entryPUB, entryUpperBound);
end

fprintf(saveFile, '%s\n', '\bottomrule');
fprintf(saveFile, '%s\n', '\end{tabular}');
fprintf(saveFile, '%s\n', '\end{center}');
fprintf(saveFile, '%s\n', '\end{table}');
fclose(saveFile);

end

function [format, entry] = findFormatAndEntry(value)

if value == Inf
    format = '& %s';
    entry = '$\infty$';
elseif value == -Inf
    format = '& %s';
    entry = '$-\infty$';
else
    format = ' & \\num[round-precision=2,round-mode=figures]{%f}';
    entry = value;
end
    
end

