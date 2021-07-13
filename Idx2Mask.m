% Eli Bowen
% 6/10/2021
% converts and index (integers indexing into an array) into a mask (logical the length of the array)
% INPUTS:
%   data - 1 x nIndices (int-valued numeric) - index (if already a mask, data will just be returned)
%   nItems - scalar (numeric) - number of items in the mask
% RETURNS:
%   data - 1 x nItems (logical)
function [data] = Idx2Mask (data, nItems)
    if isempty(data) % if empty, nothing to do (handle first = fastest)
        data = logical([]); % just make sure return datatype is right
    elseif islogical(data) % if logical, nothing to do (handle first = fastest)
        validateattributes(data, {'logical'}, {'vector','numel',nItems});
    else % if data is an index not already a mask
        validateattributes(data, {'numeric'}, {'vector','positive','integer','<=',nItems});
        validateattributes(nItems, {'numeric'}, {'nonempty','scalar','positive','integer'});
        temp = false(1, nItems);
        temp(data) = true;
        data = temp;
    end
end