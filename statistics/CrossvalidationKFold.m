%implements k-fold cross-validation
%INPUTS:
%   labels - 1D numeric array of label IDs for each datapoint
%   numFolds - number of folds (e.g. 10)
%   beRandom - OPTIONAL - iff true, datapoints will be randomly shuffled before selection (used to always be false)
%RETURNS:
%   trainIndices - indices into labels array (aka positions of datapoints) for training points, one cell per fold
%   testIndices - indices into labels array (aka positions of datapoints) for testing points, one cell per fold
function [trainIndices, testIndices] = CrossvalidationKFold (labels, numFolds, beRandom)
    assert(isnumeric(labels) && isvector(labels));
    assert(isnumeric(numFolds) && isscalar(numFolds));

    uniqueLabels = unique(labels);
    trainIndices = cell(numFolds, 1);
    testIndices = cell(numFolds, 1);
    for fold = 1:numFolds
        trainIndices{fold} = [];
        testIndices{fold} = [];
    end
    for k = 1:numel(uniqueLabels)
        catIndices = find(labels == uniqueLabels(k));
        N = numel(catIndices);
        if beRandom
            catIndices = catIndices(randperm(numel(catIndices)));
        end
        for fold = 1:numFolds
            trainIndices{fold} = [trainIndices{fold};catIndices(1:ceil((fold-1)*N/numFolds))];
            trainIndices{fold} = [trainIndices{fold};catIndices(ceil(fold*N/numFolds)+1:N)];
            testIndices{fold} = [testIndices{fold};catIndices(ceil((fold-1)*N/numFolds+1):ceil(fold*N/numFolds))];
        end
    end
end

