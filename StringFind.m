% Eli Bowen
% Like matlab's built in strfind(), but it also finds a string in a cell array of strings
% Note matlab's contains(), startsWith(), and endsWith() already support cell arrays of strings, but contains() is much slower than this function
% INPUTS:
%   str - variable to search within. If a string, returns the result of strfind(). If a cell array of strings (e.g. {'hi','there'}), returns indices into the cell array.
%   pattern - search term (a string)
%   exact - if true, will only accept exact string matches. Note search is always case sensitive. Default = 0
% RETURNS:
%   indices - empty array [] if nothing found, otherwise an array of integers
function [indices] = StringFind (str, pattern, exact)
    if iscellstr(str)
        if exact
            indices = find(strcmp(str, pattern)); % 20x faster than below
%             indices = find(not(cellfun('isempty', strfind(str, pattern))));
%             exactIndices = [];
%             for i = 1:numel(indices)
%                 if strcmp(str{indices(i)}, pattern)
%                     exactIndices = [exactIndices, indices(i)];
%                 end
%             end
%             indices = exactIndices;
        else
%             indices = find(contains(str, pattern, 'IgnoreCase', false)); % slower
            indices = find(not(cellfun('isempty', strfind(str, pattern)))); % DON'T USE CONTAINS, as recommended by matlab - it's twice as slow!
        end
    elseif ischar(str)
        if exact
            if strcmp(str, pattern)
                indices = 1;
            else
                indices = [];
            end
        else
            indices = strfind(str, pattern);
        end
    else
        error('parameter str is neither string nor cell array of strings!');
    end
end