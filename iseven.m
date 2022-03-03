% based on code created by David Coventry, 8/2/2017
% INPUTS:
%   x
% RETURNS:
%   tf
% see also: isodd
function [tf] = iseven(x)
    tf = (mod(x, 2) == 0);
end