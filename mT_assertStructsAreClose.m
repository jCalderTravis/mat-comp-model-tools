function mT_assertStructsAreClose(structA, structB)
% Check that two structs have the same fieldnames and that each field
% contains approximately equal arrays

assert(isequal(fieldnames(structA), fieldnames(structB)))

allFields = fieldnames(structA);
for iF = 1 : length(allFields)
   thisField = allFields{iF};
   
   roundedA = round(structA.(thisField), 8, 'significant');
   roundedB = round(structB.(thisField), 8, 'significant');
   
   if ~isequal(roundedA, roundedB)
       format long
       
       disp('The following were expected to be approximately equal:')
       disp(structA.(thisField))
       disp(structB.(thisField))
       disp('But there is a difference of:')
       disp(structA.(thisField) - structB.(thisField))
       
       disp('After rounding the values were:')
       disp(roundedA)
       disp(roundedB)
       disp('With a difference of:')
       disp(roundedA - roundedB)
       
       error('See above')
   end
end