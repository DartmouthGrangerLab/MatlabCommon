%Eli Bowen
%1/23/18
%provided a 1x1 struct where each field is a scalar or a 1D numeric/cell array, subsets each nonscalar field the same way
%requires that every field in this struct is either the same length or numel(myStruct.field)==1 (considered metadata)
%works on data generated e.g. by FindGoodWords.m
%INPUTS:
%   myStruct
%   keep - either logical or numeric index of items to keep
function [myStruct] = StructSubset (myStruct, keep)
    assert(isstruct(myStruct));
%     assert(isscalar(myStruct), 'myStruct must be a scalar structure'); %should uncomment this
    
    if islogical(keep) && all(keep)
        return;
    end
    names = fieldnames(myStruct);
    
    if isempty(keep)
        isEmpty = false(numel(names), 1);
        for i = 1:numel(names)
            isEmpty(i) = (ischar(myStruct.(names{i})) || isempty(myStruct.(names{i})));
        end
        if all(isEmpty)
            return; %you're asking us to do nothing
        end
    end
    
    isScalar = false(numel(names), 1);
    for i = 1:numel(names)
        isScalar(i) = (ischar(myStruct.(names{i})) || numel(myStruct.(names{i})) < 2);
    end
    if all(isScalar) && (isempty(keep) || (numel(keep) == 1 && ~keep)) %if we only have scalars and we're supposed to delete things
        error('don''t know how to delete data where every item in the struct is scalar - which fields are metadata and which vectors?');
    end
    
	for i = 1:numel(names)
        if ~ischar(myStruct.(names{i})) && numel(myStruct.(names{i})) > 1
            if islogical(keep) ||...
                    (numel(keep) == numel(myStruct.(names{i})) && all(unique(keep)==0 | unique(keep)==1))
                assert(numel(myStruct.(names{i})) == numel(keep));
%                 fieldData = getfield(wordset, names{i});
%                 wordset = setfield(wordset, names{i}, fieldData(~keep));
                myStruct.(names{i})(~keep) = [];
            else %numeric indexing
                assert(numel(unique(keep)) == numel(keep));
                myStruct.(names{i}) = myStruct.(names{i})(keep);
            end
        end
	end
end