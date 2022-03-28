% Eli Bowen 11/22/16
% NOTE: counts has the same number of elements (and same order), as unique(cellStr).
% INPUTS:
%   cellStr - cell array of strings
%   uniqueStrings - OPTIONAL
function counts = CountStringOccurrences(cellStr, uniqueStrings)
    if ~exist('uniqueStrings', 'var') || isempty(uniqueStrings)
        uniqueStrings = unique(cellStr);
    end
    counts = cellfun(@(x) sum(ismember(cellStr,x)), uniqueStrings, 'un', 0);
    counts = cell2mat(counts); % should all be numeric
end