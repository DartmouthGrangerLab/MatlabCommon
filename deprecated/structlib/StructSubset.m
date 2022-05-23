% Eli Bowen 1/23/18
% provided a 1x1 struct where each field is a scalar or a 1D numeric/cell array, subsets each nonscalar field the same way
% requires that every field in this struct is either the same length or numel(myStruct.field)==1 (considered metadata)
% works on data generated e.g. by FindGoodWords.m
% INPUTS:
%   s    - scalar (struct)
%   keep - 1 x n_items (logical mask or integer index) entries to KEEP
%   fields2Exclude - OPTIONAL (comma-separated char or cell array of chars) list of fieldnames to NOT subset (e.g. fields that aren't the same length as the rest)
% see also StructFilter
function s = StructSubset(s, keep, fields2Exclude)
    validateattributes(s, {'struct'}, {'nonempty','scalar'}, 1);
    validateattributes(keep, {'numeric','logical'}, {}, 2);
    if islogical(keep) && all(keep)
        return % nothing to do
    end

    fn = fieldnames(s);

    % remove fields2Exclude
    if exist('fields2Exclude', 'var') && ~isempty(fields2Exclude)
        fields2Exclude = ParseList(fields2Exclude);
        idx = zeros(1, numel(fields2Exclude));
        for i = 1 : numel(fields2Exclude)
            temp = find(strcmp(fn, fields2Exclude{i}));
            assert(numel(temp) == 1, ['asked to exclude [',fields2Exclude{i},'], but it doesnt exist']);
            idx(i) = temp;
        end
        fn(idx) = [];
        if isempty(fn)
            return % nothing to do
        end
    end

    if isempty(keep)
        isEmpty = false(1, numel(fn));
        for i = 1 : numel(fn)
            isEmpty(i) = (ischar(s.(fn{i})) || isempty(s.(fn{i})));
        end
        if all(isEmpty)
            return % nothing to do
        end
    end

    isScalar = false(1, numel(fn));
    for i = 1 : numel(fn)
        isScalar(i) = (ischar(s.(fn{i})) || numel(s.(fn{i})) < 2);
    end
    if all(isScalar) && (isempty(keep) || (numel(keep) == 1 && ~keep)) % if we only have scalars and we're supposed to delete things
        error('don''t know how to delete data where every item in the struct is scalar - which fields are metadata and which vectors?');
    end

    % subset each field
	for i = 1 : numel(fn)
        if ~ischar(s.(fn{i})) && numel(s.(fn{i})) > 1
            if islogical(keep) ||...
                    (numel(keep) == numel(s.(fn{i})) && all(unique(keep)==0 | unique(keep)==1))
                assert(numel(s.(fn{i})) == numel(keep));
%                 fieldData = getfield(s, fn{i});
%                 wordset = setfield(s, fn{i}, fieldData(~keep));
                s.(fn{i})(~keep) = [];
            else % numeric indexing
                assert(numel(unique(keep)) == numel(keep));
                s.(fn{i}) = s.(fn{i})(keep);
            end
        end
	end
end