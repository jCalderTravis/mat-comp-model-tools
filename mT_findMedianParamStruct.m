function MedianParams = mT_findMedianParamStruct(DSet, modelNum)
% Looks at the best fitting parameters for modelNum, and returns a param
% struct containing the mean best fitting params across participants.

% TESTING
% If pass DSet as the string 'test', runs tests instead.

if strcmp(DSet, 'test')
    testFun()
    return
end


paramNames = fieldnames(DSet.P(1).Models(modelNum).BestFit.Params);
for iP = 1 : length(paramNames)
    
    [relParams, stackDim] ...
        = mT_stackData(DSet.P, ...
        @(st) st.Models(modelNum).BestFit.Params.(paramNames{iP}));
    
    MedianParams.(paramNames{iP}) = median(relParams, stackDim);
end
    
end


function testFun()
% Set up a dummy structure and check reuslt of applying the function

DSet = struct();
DSet.P(1).Models(2).BestFit.Params.Param1 = 1;
DSet.P(2).Models(2).BestFit.Params.Param1 = 2;
DSet.P(3).Models(2).BestFit.Params.Param1 = 3;
    
DSet.P(1).Models(2).BestFit.Params.Param2 = [2, 3, 4];
DSet.P(2).Models(2).BestFit.Params.Param2 = [2, 3, 4] + 1;
DSet.P(3).Models(2).BestFit.Params.Param2 = [2, 3, 4] + 2;

DSet.P(1).Models(2).BestFit.Params.Param3 = [2, 3, 4]' + 1;
DSet.P(2).Models(2).BestFit.Params.Param3 = [2, 3, 4]' + 2;
DSet.P(3).Models(2).BestFit.Params.Param3 = [2, 3, 4]' + 3;

DSet.P(1).Models(2).BestFit.Params.Param4 = [3, 4, 5; 6, 7, 8];
DSet.P(2).Models(2).BestFit.Params.Param4 = [3, 4, 5; 6, 7, 8] + 1;
DSet.P(3).Models(2).BestFit.Params.Param4 = [3, 4, 5; 6, 7, 8] + 2;

MedianParams = mT_findMedianParamStruct(DSet, 2);

assert(isequal(MedianParams.Param1, 2))
assert(isequal(MedianParams.Param2, [3, 4, 5]))
assert(isequal(MedianParams.Param3, [4, 5, 6]'))
assert(isequal(MedianParams.Param4, [4, 5, 6; 7, 8, 9]))

disp('findMedianParamStruct passed 1 test')

end


    