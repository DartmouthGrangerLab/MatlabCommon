% Eli Bowen 11/19/2021
% count data that can't be 0 (aka positive integers)
% INPUTS:
%   x
function [] = mustBeFraction(x)
    try
        mustBeNumeric(x);
        mustBeGreaterThanOrEqual(x, 0);
        mustBeLessThanOrEqual(x, 1);
        mustBeNonNan(x);
    catch ex
        throwAsCaller(ex);
    end
end