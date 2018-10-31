%implements leave-k-out bootstrapped cross-validation
%INPUTS:
%   labels - 1D numeric array of label IDs for each datapoint
%   numValidations - number of bootstrapped cross-validations to perform
%   fractionTest - OPTIONAL - number between 0 and 1, describing what fraction of the data for each class should be used for testing (DEFAULT = 0.5)
%   beRandom - iff true, datapoints will be randomly shuffled before selection (used to always be true)
%RETURNS:
%   trainIndices - indices into labels array (aka positions of datapoints) for training points, one cell per validation trial
%   testIndices - indices into labels array (aka positions of datapoints) for testing points, one cell per validation trial
function [trainIndices, testIndices] = CrossvalidationLeaveKOut (labels, numValidations, fractionTest, beRandom)
    assert(isnumeric(labels) && isvector(labels));
    assert(isnumeric(numValidations) && isscalar(numValidations));
    if ~exist('fractionTest','var') || isempty(fractionTest)
        fractionTest = 0.5;
    end

    uniqueLabels = unique(labels);
    trainIndices = cell(numValidations, 1);
    testIndices = cell(numValidations, 1);
    for trial = 1:numValidations
        trainIndices{trial} = [];
        testIndices{trial} = [];
    end
    for trial = 1:numValidations
        for k = 1:numel(uniqueLabels)
            catIndices = find(labels == uniqueLabels(k));
            nTest = ceil(numel(catIndices) * fractionTest); %num test
            nTrain = numel(catIndices) - nTest; %num train
            if beRandom
                catIndices = catIndices(randperm(numel(catIndices)));
            end

            trainIndices{trial} = vertcat(trainIndices{trial}, catIndices(1:nTrain));

            uniqueTestCount = numel(catIndices(nTrain+1:end));
            if uniqueTestCount >= nTest
                testIndices{trial} = vertcat(testIndices{trial}, catIndices(nTrain+1:nTrain+nTest));
            else
                testIndices{trial} = vertcat(testIndices{trial}, catIndices(end-(nTest-1):end));
            end
        end
    end
end

