% Eli Bowen 11/19/2021
% count data (non-negative integers)
% INPUTS:
%   x
% RETURNS:
%   tf - same dimensionality as x (logical)
function tf = IsCount(x)
    tf = isnumeric(x) & x >= 0 & mod(x, 1) == 0 & ~isnan(x);
end