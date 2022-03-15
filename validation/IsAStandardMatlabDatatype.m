% Eli bowen 11/9/2021
% returns rue if x is a commonly used matlab datatype
% INPUTS:
%   x
% RETURNS:
%   tf
function [tf] = IsAStandardMatlabDatatype(x)
    tf = isa(x, 'numeric') || isa(x, 'logical') || isa(x, 'struct') || isa(x, 'cell') || isa(x, 'table') || isa(x, 'char') || isa(x, 'string');
end