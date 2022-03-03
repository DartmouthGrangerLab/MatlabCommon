% INPUTS:
%   labels - 1D numeric array of label IDs for each datapoint
%   frac - fraction of data to keep (0 to 1)
% RETURNS:
%   idx - indices into a random percent of the datapoints for each class
function [idx] = RandSubsetDataset(labels, frac)
    validateattributes(labels, 'numeric', {});
    validateattributes(frac, 'numeric', {'nonempty','scalar','nonnegative'});

    idx = [];
    uniqLabels = unique(labels);
    for k = 1 : numel(uniqLabels)
        catIndices = find(labels == uniqLabels(k));
        N = numel(catIndices);

        randIdx = randperm(N);
        randIdx = randIdx(1:round(N*frac));
        idx = [idx;catIndices(randIdx)];
    end
end