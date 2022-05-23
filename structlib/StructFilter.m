% Eli Bowen 6/16/2021
% filter entries of each field in a struct (recursive), ignoring cells
% INPUTS:
%   s    - scalar (struct)
%   keep - 1 x n_items (logical mask or integer index) entries to KEEP
%   dim  - scalar dimension to keep, or 'vector' to use vector indexing
% see also StructSubset
function s = StructFilter(s, keep, dim)
    validateattributes(s, {'struct'}, {'nonempty','scalar'}, 1);
    validateattributes(keep, {'numeric','logical'}, {}, 2);
    validateattributes(dim, {'numeric','char'}, {'nonempty'}, 3);
    if islogical(keep) && all(keep)
        return % nothing to do
    end

    fn = fieldnames(s);
    for i = 1 : numel(fn)
        if isstruct(s.(fn{i}))
            s.(fn{i}) = StructFilter(s.(fn{i}), keep, dim);
        elseif ~iscell(s.(fn{i})) && ~isempty(s.(fn{i}))
            if strcmp(dim, 'vector')
                s.(fn{i}) = s.(fn{i})(keep);
            elseif dim == 1
                s.(fn{i}) = s.(fn{i})(keep,:);
            elseif dim == 2
                s.(fn{i}) = s.(fn{i})(:,keep);
            elseif dim == 3
                s.(fn{i}) = s.(fn{i})(:,:,keep);
            elseif dim == 4
                s.(fn{i}) = s.(fn{i})(:,:,:,keep);
            else
                error('unexpected dim (or its too large)');
            end
        end
    end
end