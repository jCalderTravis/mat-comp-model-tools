function mT_produceStatsLatexSnippet(resultsTable)
% Takes the results table produced by 'mT_analyseParams' and produces text
% snippets which can be copied and pasted into Latex to report statistics.

% NOTE
% For use in latex, need to have the package siunitx
% Reviewed 17.09.2023

for iStat = 1 : size(resultsTable, 1)
    
    df = [' \num[round-precision=2,round-mode=figures]{ ' ...
        num2str(resultsTable{iStat, 'df'}) '}'];
    tVal = [' \num[round-precision=2,round-mode=figures]{ ' ...
        num2str(resultsTable{iStat, 'tstat'}) '}'];
    pValue = [' \num[round-precision=2,round-mode=figures]{ ' ...
        num2str(resultsTable{iStat, 'pValue'}) '}'];
    if strcmp(resultsTable{iStat, 'tails'}, 'two-tailed')
        tails = [];
    else
        tails = ['\text{ ' resultsTable{iStat, 'tails'}{:} ' }, '];
    end
    effectSize = [' \num[round-precision=2,round-mode=figures]{ ' ...
        num2str(resultsTable{iStat, 'effectD'}) '}'];
    
    snippet = ['($ t(' df ')= ' tVal '$, $p= ' pValue '$, ' ...
        tails '$d=' effectSize '$)'];
    
    disp(resultsTable{iStat, 'paramNames'})
    disp(snippet)
    disp(' ')
    disp(' ')
    disp(' ')

end

