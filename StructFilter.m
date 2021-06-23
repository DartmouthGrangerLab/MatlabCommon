% Eli Bowen
% 6/16/2021
% filter entries of each field in a struct (recursive), ignoring cells
% INPUTS:
%   s
%   mask - logical or integer vector of entries to KEEP
%   dim - dimension to mask, or 'vector' to use vector indexing
function [s] = StructFilter (s, mask, dim)
    validateattributes(s, {'struct'}, {'nonempty','scalar'});
    validateattributes(mask, {'numeric','logical'}, {});
    validateattributes(dim, {'numeric','char'}, {'nonempty'});

    if islogical(mask) && all(mask)
        return; % nothing to do
    end
    
    fn = fieldnames(s);
    for i = 1:numel(fn)
        if isstruct(s.(fn{i}))
            s.(fn{i}) = StructFilter(s.(fn{i}), mask, dim);
        elseif ~iscell(s.(fn{i})) && ~isempty(s.(fn{i}))
            if strcmp(dim, 'vector')
                s.(fn{i}) = s.(fn{i})(mask);
            elseif dim == 1
                s.(fn{i}) = s.(fn{i})(mask,:);
            elseif dim == 2
                s.(fn{i}) = s.(fn{i})(:,mask);
            elseif dim == 3
                s.(fn{i}) = s.(fn{i})(:,:,mask);
            elseif dim == 4
                s.(fn{i}) = s.(fn{i})(:,:,:,mask);
            else
                error('unexpected dim (or its too large)');
            end
        end
    end
end