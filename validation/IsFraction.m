% Eli Bowen 11/19/2021
% count data that can't be 0 (aka positive integers)
% INPUTS:
%   x
% RETURNS:
%   tf - same dimensionality as x (logical)
function tf = IsFraction(x)
    tf = isnumeric(x) & x >= 0 & x <= 1 & ~isnan(x);
end