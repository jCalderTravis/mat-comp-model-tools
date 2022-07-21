function mT_assertStructsAreClose(structA, structB)
% Check that two structs have the same fieldnames and that each field
% contains approximately equal arrays

assert(isequal(fieldnames(structA), fieldnames(structB)))

allFields = fieldnames(structA);
for iF = 1 : length(allFields)
   thisField = allFields{iF};
   
   try
       assert(isequal(...
           round(structA.(thisField), 6), ...
           round(structB.(thisField), 6) ...
           ))
   catch err
       disp('The following were expected to be approximately equal:')
       disp(structA.(thisField))
       disp(structB.(thisField))
       disp('But there is a difference off:')
       disp(structA.(thisField) - structB.(thisField))
       rethrow(err)
   end
end