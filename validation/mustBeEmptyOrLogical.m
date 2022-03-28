% Eli Bowen 11/30/2021
% INPUTS:
%   x
function [] = mustBeEmptyOrLogical(x)
    try
        assert(isempty(x) || islogical(x));
    catch ex
        throwAsCaller(ex);
    end
end