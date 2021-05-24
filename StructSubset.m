% Eli Bowen
% 1/23/18
% provided a 1x1 struct where each field is a scalar or a 1D numeric/cell array, subsets each nonscalar field the same way
% requires that every field in this struct is either the same length or numel(myStruct.field)==1 (considered metadata)
% works on data generated e.g. by FindGoodWords.m
% INPUTS:
%   s - struct
%   keep - vector - either logical mask or numeric index of items to keep
%   fields2Exclude - OPTIONAL - char or cell array of chars - list of fieldnames to NOT subset (e.g. fields that aren't the same length as the rest)
function [s] = StructSubset (s, keep, fields2Exclude)
    validateattributes(s, {'struct'}, {'nonempty','scalar'});
    validateattributes(keep, {'numeric','logical'}, {});

    names = fieldnames(s);

    %% preprocessing
    if islogical(keep) && all(keep)
        return;
    end

    % remove fields2Exclude
    if exist('fields2Exclude', 'var') && ~isempty(fields2Exclude)
        if ischar(fields2Exclude)
            fields2Exclude = {fields2Exclude};
        end
        idx = zeros(1, numel(fields2Exclude));
        for i = 1:numel(fields2Exclude)
            temp = find(strcmp(names, fields2Exclude{i}));
            assert(numel(temp) == 1, ['asked to exclude [',fields2Exclude{i},'], but it doesnt exist']);
            idx(i) = temp;
        end
        names(idx) = [];
        if isempty(names)
            return; % you're asking us to do nothing
        end
    end

    if isempty(keep)
        isEmpty = false(1, numel(names));
        for i = 1:numel(names)
            isEmpty(i) = (ischar(s.(names{i})) || isempty(s.(names{i})));
        end
        if all(isEmpty)
            return; % you're asking us to do nothing
        end
    end

    isScalar = false(1, numel(names));
    for i = 1:numel(names)
        isScalar(i) = (ischar(s.(names{i})) || numel(s.(names{i})) < 2);
    end
    if all(isScalar) && (isempty(keep) || (numel(keep) == 1 && ~keep)) % if we only have scalars and we're supposed to delete things
        error('don''t know how to delete data where every item in the struct is scalar - which fields are metadata and which vectors?');
    end

    %% subset each field
	for i = 1:numel(names)
        if ~ischar(s.(names{i})) && numel(s.(names{i})) > 1
            if islogical(keep) ||...
                    (numel(keep) == numel(s.(names{i})) && all(unique(keep)==0 | unique(keep)==1))
                assert(numel(s.(names{i})) == numel(keep));
%                 fieldData = getfield(s, names{i});
%                 wordset = setfield(s, names{i}, fieldData(~keep));
                s.(names{i})(~keep) = [];
            else % numeric indexing
                assert(numel(unique(keep)) == numel(keep));
                s.(names{i}) = s.(names{i})(keep);
            end
        end
	end
end