function resultsTable = mT_analyseParams(paramData, paramNames, varargin)
% Analyse the parameters inferred for a single model. 

% INPUT
% paramData specified in a (numParams)*(numParticipants) array.
% paramNames: Cell array of the names of the parameters (as strings), in the 
% order in paramData. Should be a column cell array.
% varargin: If want one-tailed t-tests provide 'left' or 'right'

% TESTING
% If pass infoCrit as the string 'test', runs tests instead.

if strcmp(paramData, 'test')
    testFun()
    return
end

if isempty(varargin)
   oneTailed = false;
elseif strcmp(varargin{1}, 'left') || strcmp(varargin{1}, 'right')
   oneTailed = true;
   tail = varargin{1};
else
    error('Incorrect use of inputs')
end

avParamVal = NaN(size(paramData, 1), 1);
lowerCI = NaN(size(paramData, 1), 1);
upperCI = NaN(size(paramData, 1), 1);
pValue = NaN(size(paramData, 1), 1);
varience = NaN(size(paramData, 1), 1);
tstat = NaN(size(paramData, 1), 1);
df = NaN(size(paramData, 1), 1);
effectD = NaN(size(paramData, 1), 1);
tails = cell(size(paramData, 1), 1);

for iParam = 1 : size(paramData, 1)
    avParamVal(iParam) = nanmean(paramData(iParam, :));
    
    if oneTailed
        [~, pValue(iParam), CI, stats] = ttest(paramData(iParam, :), 0, ...
            'Tail', tail);
    else
        [~, pValue(iParam), CI, stats] = ttest(paramData(iParam, :));
    end
    
    df(iParam) = stats.df;
    tstat(iParam) = stats.tstat;
    effectD(iParam) = avParamVal(iParam)/stats.sd;
    lowerCI(iParam) = CI(1);
    upperCI(iParam) = CI(2);
    varience(iParam) = (nanstd(paramData(iParam, :))^2);
    
    if oneTailed
        tails{iParam} = 'one-tailed';
    else
        tails{iParam} = 'two-tailed';
    end
    
end

namesShape = size(paramNames);
if namesShape(2) ~= 1; error('Column cell array expected.'); end
    
resultsTable = table(paramNames, pValue, df, tstat, effectD, avParamVal, ...
    lowerCI, upperCI, varience, tails);


end

function testFun()

paramData = [1, 1, 1, NaN, 1, 1; ...
    -2, -1, 1, NaN, 2, 0; ...
    0, 0, 100, NaN, 100, 0; ...
    0, 0, -100, NaN, -100, 0];
paramNames = {'P1', 'P2', 'P3', 'P4'}';

resultsTable = mT_analyseParams(paramData, paramNames);

assert(resultsTable.pValue(1)<0.0001)
assert(resultsTable.pValue(2)>0.99)
assert(resultsTable.pValue(3) == resultsTable.pValue(4))
assert(all(resultsTable.df == 4))
assert(resultsTable.effectD(1) > 20)
assert(resultsTable.effectD(2) == 0)
assert(resultsTable.effectD(3) > 0)
assert(resultsTable.effectD(3) == -resultsTable.effectD(4))
assert(resultsTable.avParamVal(1) == 1)
assert(resultsTable.avParamVal(2) == 0)
assert(resultsTable.avParamVal(3) > 0)
assert(resultsTable.avParamVal(3) == -resultsTable.avParamVal(4))
assert(resultsTable.lowerCI(1) == 1)
assert(resultsTable.upperCI(1) == 1)
assert(resultsTable.lowerCI(2) > -2)
assert(resultsTable.lowerCI(2) < 0)
assert(resultsTable.upperCI(2) < 2)
assert(resultsTable.upperCI(2) > 0)
assert(resultsTable.lowerCI(3) < 100)
assert(resultsTable.upperCI(3) > 0)
assert(resultsTable.lowerCI(3) == -resultsTable.upperCI(4))
assert(resultsTable.upperCI(3) == -resultsTable.lowerCI(4))
assert(resultsTable.varience(1) == 0)
assert(all(resultsTable.varience(2:end) > 0))

% Run a one-tailed test this time
resultsTable = mT_analyseParams(paramData, paramNames, 'left');

assert(resultsTable.pValue(1)>0.999)
assert(resultsTable.pValue(2)==0.5)
assert(resultsTable.pValue(3) > resultsTable.pValue(4))
assert(resultsTable.pValue(4)>0.01)
assert(all(resultsTable.df == 4))
assert(resultsTable.effectD(1) > 20)
assert(resultsTable.effectD(2) == 0)
assert(resultsTable.effectD(3) > 0)
assert(resultsTable.effectD(3) == -resultsTable.effectD(4))
assert(resultsTable.avParamVal(1) == 1)
assert(resultsTable.avParamVal(2) == 0)
assert(resultsTable.avParamVal(3) > 0)
assert(resultsTable.avParamVal(3) == -resultsTable.avParamVal(4))
assert(resultsTable.upperCI(1) == 1)
assert(resultsTable.lowerCI(2) < 0)
assert(resultsTable.upperCI(2) < 2)
assert(resultsTable.upperCI(2) > 0)
assert(resultsTable.lowerCI(3) < 100)
assert(resultsTable.upperCI(3) > 0)
assert(resultsTable.upperCI(3) < 100)
assert(resultsTable.varience(1) == 0)
assert(all(resultsTable.varience(2:end) > 0))

disp('mT_analyseParams passed 1 test')
end
