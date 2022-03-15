% Eli Bowen 11/19/2021
% count data that can't be 0 (aka positive integers)
% INPUTS:
%   x
% RETURNS:
%   tf - same dimensionality as x (logical)
function [tf] = IsIdx(x)
    tf = isnumeric(x) & x > 0 & mod(x, 1) == 0 & ~isnan(x);
end