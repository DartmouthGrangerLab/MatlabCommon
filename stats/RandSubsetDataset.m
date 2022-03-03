%return indices into a random percent of the datapoints for each class
%INPUTS:
%   labels - 1D numeric array of label IDs for each datapoint
%   frac - fraction of data to keep (0 to 1)
function [indices] = RandSubsetDataset (labels, frac)
    indices = [];
    uniqueLabels = unique(labels);
    for k = 1:numel(uniqueLabels)
        catIndices = find(labels == uniqueLabels(k));
        N = numel(catIndices);
        
        randIdx = randperm(N);
        randIdx = randIdx(1:round(N*frac));
        indices = [indices;catIndices(randIdx)];
    end
end