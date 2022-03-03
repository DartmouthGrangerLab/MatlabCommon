% Eli Bowen
% 2/2022
% INPUTS:
%   data - 1 x n (numeric)
%   k    - scalar (int-valued numeric)
% RETURNS:
%   data - 1 x n (numeric) if input is on gpu or sparse, so is output
function [data] = KWTA(data, k)
    validateattributes(data, 'numeric', {});
    validateattributes(k, 'numeric', {'nonempty','scalar','integer'});

    [~,idx] = maxk(data, k);
    data(:) = 0;
    data(idx) = 1;
end