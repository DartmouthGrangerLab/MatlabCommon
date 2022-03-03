% Eli Bowen 6/10/2021
% converts an index (integers indexing into an array) into a mask (logical the length of the array)
% INPUTS:
%   data - 1 x n_indices (int-valued numeric) index (if already a mask, data will just be returned)
%   nItems - scalar (numeric) number of items in the mask
% RETURNS:
%   data - 1 x n_items (logical)
function [data] = Idx2Mask(data, n_items)
    if isempty(data) % if empty, nothing to do (handle first = fastest)
        data = logical([]); % just make sure return datatype is right
    elseif islogical(data)
        validateattributes(data, 'logical', {'vector','numel',n_items}); % nothing to do (handle first = fastest)
    else % data is an index not already a mask
        validateattributes(data, 'numeric', {'vector','positive','integer','<=',n_items});
        validateattributes(n_items, 'numeric', {'nonempty','scalar','positive','integer'});
        temp = false(1, n_items);
        temp(data) = true;
        data = temp;
    end
end