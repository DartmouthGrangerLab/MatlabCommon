% based on code created by David Coventry, 8/2/2017
% INPUTS:
%   x
% RETURNS:
%   tf
% see also: iseven
function tf = isodd(x)
    tf = (mod(x, 2) == 1);
end