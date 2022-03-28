% Eli Bowen 4/23/2017
% converts a 1D cell array of strings (e.g. {'cat1','cat1','cat2','cat2'}) to a numeric array (e.g. [1,1,2,2])
% numeric IDs are consecutive numbers starting with 1, ordered the same as unique(stringLabels).
% see the code for details - it's simple
% INPUTS:
%   stringLabels - 1 x d (cell array of strings)
% RETURNS:
%   numericIDs - 1 x d (numeric) numericIDs(i) corresponds to stringLabels{i}
%   dictionary - a numericID of i corresponds to dictionary{i}.
function [numericIDs,dictionary] = StringLabels2Numeric(stringLabels)
    assert(iscell(stringLabels) && sum(size(stringLabels)>1) == 1, 'stringLabels must be a 1D cell array');
    dictionary = unique(stringLabels);
    
	numericIDs = zeros(numel(stringLabels), 1);
    for i = 1 : numel(stringLabels)
        numericIDs(i) = StringFind(dictionary, stringLabels{i}, true);
    end
end