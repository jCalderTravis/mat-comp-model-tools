function mT_assertStructsAreClose(structA, structB)
% Check that two structs have the same fieldnames and that each field
% contains approximately equal arrays

assert(isequal(fieldnames(structA), fieldnames(structB)))

allFields = fieldnames(structA);
for iF = 1 : length(allFields)
   thisField = allFields{iF};
   
   assert(isequal(...
       round(structA.(thisField), 10), ...
       round(structB.(thisField), 10) ...
       ))
end