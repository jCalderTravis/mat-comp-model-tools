function dataStruct = mT_removeFunctionHandles(dataStruct, exceptions)
% Go through every structure field, and cell element. If a function handle is
% present convert to string.

% INPUT
% exceptions: Cell array. Any field with a name matching a string in exceptions
% will be exempt.

% NOTES
% The advantage of doing this is that when save a function handle, all the data
% passed to it at the time of its creation is also saved. This can lead to an
% enourmous inflation in the size of the data structure, and an uncessesary one
% if the function handles are only in the structure as a record and will not be
% used again.

% HISTORY
% Reviewed 2020

if nargin < 2
    exceptions = {};
end

if isstruct(dataStruct)    
    for iElement = 1 : length(dataStruct(:))
        
        fields = fieldnames(dataStruct(iElement));
        for iField = 1 : length(fields)
            
            % Is this field exempt?
            if ismember(fields{iField}, exceptions)
                continue 
            end
            
            subStructure = dataStruct(iElement).(fields{iField});
            subStructure = actOnSubStructure(subStructure, exceptions);
            
            % Now put the modified structure back
            dataStruct(iElement).(fields{iField}) = subStructure;
        end
    end
    
elseif iscell(dataStruct)
    for iElement = 1 : length(dataStruct(:))
        
        subStructure = dataStruct{iElement};
        subStructure = actOnSubStructure(subStructure, exceptions);
        
        % Now put the modified cell back
        dataStruct{iElement} = subStructure;
    end
end

end


function subStructure = actOnSubStructure(subStructure, exceptions)

if isstruct(subStructure) || iscell(subStructure)
    % We have found a nested cell/structure in the original
    % structure. Run the function again on this sub-strcuture!
    subStructure = mT_removeFunctionHandles(subStructure, exceptions);
    
elseif isa(subStructure,'function_handle')
    subStructure = func2str(subStructure);
    
end

end