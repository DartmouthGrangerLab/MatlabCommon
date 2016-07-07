%Like matlab's built in strfind(), but it also finds a string in a cell array of strings.
%INPUTS:
%   str - variable to search within. If a string, returns the result of strfind(). If a cell array of strings (e.g. {'hi','there'}), returns indices into the cell array.
%   pattern - search term (a string)
%   exact - OPTIONAL if 1, will only accept exact string matches. Note search is always case sensitive. Default = 0
%RETURNS:
%   indices - empty array [] if nothing found, otherwise an array of integers
function [indices] = StringFind (str, pattern, exact)
    if ~exist('exact', 'var') || isempty(exact)
        exact = 0;
    end
    
    if iscellstr(str)
        indexC = strfind(str, pattern);
        indices = find(not(cellfun('isempty', indexC)));
        if exact == 1
            exactIndices = [];
            for i = 1:numel(indices)
                if strcmp(str{indices(i)}, pattern)
                    exactIndices = [exactIndices, indices(i)];
                end
            end
            indices = exactIndices;
        end
    elseif ischar(str)
        if exact == 1
            if strcmp(str, pattern)
                indices = 1;
            else
                indices = [];
            end
        else
            indices = strfind(str, pattern);
        end
    else
        error('Parameter str is neither string nor cell array of strings!');
    end
end