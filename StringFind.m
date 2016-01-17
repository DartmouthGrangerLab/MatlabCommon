%Like matlab's built in strfind(), but it also finds a string in a cell array of strings.
%INPUTS:
%   str - variable to search within. If a string, returns the result of strfind(). If a cell array of strings (e.g. {'hi','there'}), returns indices into the cell array.
%   pattern - search term (a string)
%RETURNS:
%   indices - 
function [indices] = StringFind (str, pattern)
    if iscellstr(str)
        indexC = strfind(str, pattern);
        indices = find(not(cellfun('isempty', indexC)));
    elseif ischar(str)
        indices = strfind(str, pattern);
    else
        error('Parameter str is neither string nor cell array of strings!');
    end
end