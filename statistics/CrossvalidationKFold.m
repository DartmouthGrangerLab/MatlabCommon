%implements k-fold cross-validation
%INPUTS:
%   labels - 1D numeric array of label IDs for each datapoint
%   numFolds - (OPTIONAL) number of folds (defualt = 10)
%RETURNS:
%   trainIndices - indices into labels array (aka positions of datapoints) for training points, one cell per fold
%   testIndices - indices into labels array (aka positions of datapoints) for testing points, one cell per fold
function [trainIndices, testIndices] = CrossvalidationKFold (labels, numFolds)
    if ~exist('numFolds','var') || isempty(numFolds)
        numFolds = 10;
    end

    trainIndices = cell(numFolds, 1);
    testIndices = cell(numFolds, 1);
    for fold = 1:numFolds
        trainIndices{fold} = [];
        testIndices{fold} = [];
    end
    for k = 1:numel(unique(labels))
        catIndices = find(labels == k);
        N = numel(catIndices);
        for fold = 1:numFolds
            trainIndices{fold} = [trainIndices{fold};catIndices(1:ceil((fold-1)*N/numFolds))];
            trainIndices{fold} = [trainIndices{fold};catIndices(ceil(fold*N/numFolds)+1:N)];
            testIndices{fold} = [testIndices{fold};catIndices(ceil((fold-1)*N/numFolds+1):ceil(fold*N/numFolds))];
        end
    end
end

