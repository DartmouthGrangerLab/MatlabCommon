% Eli Bowen
% 11/19/2021
% INPUTS:
%   x
function [] = mustBeCount (x)
    try
        mustBeNumeric(x);
        mustBeNonnegative(x);
        mustBeInteger(x);
        mustBeNonNan(x);
    catch ex
        throwAsCaller(ex);
    end
end