function [stacked, stackDim] = mT_stackData(DataStruct, structPath)
% Takes the data from a specific field in a struct array, and stacks it along
% the first unused dimention unless the data is scalar. In the case that the
% data is scalar, data is stacked along the second dimention. 

% INPUT
% DataStruct    The struct array from which to extract data
% structPath    A function handle. The function should return the field from
%               which to extract data when DataStruct is provided as an argument.
%               Data will be extracted from this field for every struct in the
%               struct array.
%               eg. @(struct) struct.Colour(2).Edges

% OUTPUT
% stackDim: The dimention the data has been stacked along (always the last, 
% unless the input data is scalar in which case it is along the second dimention).

% TESTING
% If pass DataStruct as the string 'test', runs tests instead.

% HISTORY
% Reviewed 2020

if strcmp(DataStruct, 'test')
    testFun()
    return
end

% If the strct array only has one element no stacking is required
if length(DataStruct) == 1
    stacked = structPath(DataStruct);
    stackDim = nan;
    return
end

% Check the data to concatinate is all of the size shape, and find how many
% dimentions it has
findSize = @(struct) size(structPath(struct));
dataSizes = arrayfun(findSize, DataStruct, 'UniformOutput', false);
assert(isequal(dataSizes{:}))

% Find the properties of the data
dataShape = dataSizes{1};
dataDim = length(dataShape);
stackDim = dataDim +1;

if dataShape(end) == 1
    dataShape(end) = [];
    dataDim = dataDim -1;
    stackDim = stackDim -1;
end

% Now we know the size, stack the relevant data
stacked = NaN([dataShape, length(DataStruct)]);

% Depending on the number of dimentions in the data, the dimention along which
% we will stack will vary. Create a function to index all the elements at
% a particular points along this new dimention.
findSlice = @(slice) [repmat({':'}, 1, dataDim), slice];


% Perform the stacking
for iStruct = 1 : length(DataStruct)
    
    sliceIndex = findSlice(iStruct);
    stacked(sliceIndex{:}) = structPath(DataStruct(iStruct));
end

end

function testFun()
% Set up a dummy structure and check reuslt of applying the function
Test = struct();
for iP = 1 : 34
    Test.P(iP).General = iP;
    Test.P(iP).Data.Response = [1, 0, 1, 0, 1]' + iP;
    Test.P(iP).Data.Accuracy = [1, 0, 1, 0, 1] + iP;
    Test.P(iP).Data.Stimulus = [1 2 3; 4 5 6] * iP;
end

[stacked, stackDim] = mT_stackData(Test.P, @(str) str.General);
assert(stackDim == 2)
assert(isequal(stacked, 1:34))

[stacked, stackDim] = mT_stackData(Test.P, @(str) str.Data.Response);
assert(stackDim == 2)
expectedResult = repmat([1, 0, 1, 0, 1]', 1, 34) + [1:34];
assert(isequal(stacked, expectedResult))

[stacked, stackDim] = mT_stackData(Test.P, @(str) str.Data.Accuracy);
assert(stackDim == 3)
ptpntNumber = nan(1, 1, 34);
ptpntNumber(:) = 1 : 34;
expectedResult = repmat([1, 0, 1, 0, 1], 1, 1, 34) + ptpntNumber;
assert(isequal(stacked, expectedResult))

[stacked, stackDim] = mT_stackData(Test.P, @(str) str.Data.Stimulus);
assert(stackDim == 3)
expectedResult = repmat([1 2 3; 4 5 6], 1, 1, 34) .* ptpntNumber;
assert(isequal(stacked, expectedResult))

disp('mT_stackData passed 1 test')

end