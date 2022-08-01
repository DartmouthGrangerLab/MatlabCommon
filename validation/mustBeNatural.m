% Eli Bowen 11/19/2021
% natural numbers (non-negative integers)
% INPUTS
%   x
function [] = mustBeNatural(x)
    try
        mustBeNumeric(x);
        mustBeNonnegative(x);
        mustBeInteger(x);
        mustBeNonNan(x);
    catch ex
        throwAsCaller(ex);
    end
end