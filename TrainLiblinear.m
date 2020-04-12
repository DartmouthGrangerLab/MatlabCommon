%Eli Bowen
%9/12/2018
%wrapper designed to simplify and remove the chance of errors when calling liblinear's train() function
%designed to work with liblinear-multicore-2.20
%INPUTS:
%   solverType - one of:
%       For multi-class classification:
%       0 -- L2-regularized logistic regression (primal)
%       1 -- L2-regularized L2-loss support vector classification (dual)
%       2 -- L2-regularized L2-loss support vector classification (primal)
%       3 -- L2-regularized L1-loss support vector classification (dual)
%       4 (NOT SUPPORTED YET) -- support vector classification by Crammer and Singer
%       5 (MAYBE SUPPORTED) -- L1-regularized L2-loss support vector classification
%       6 (NOT SUPPORTED YET) -- L1-regularized logistic regression
%       7 (MAYBE SUPPORTED) -- L2-regularized logistic regression (dual)
%       For regression:
%       11 -- L2-regularized L2-loss support vector regression (primal)
%       12 (NOT SUPPORTED YET) -- L2-regularized L2-loss support vector regression (dual)
%       13 (NOT SUPPORTED YET) -- L2-regularized L1-loss support vector regression (dual)
%   labels - an Nx1 numeric vector of category IDs for the data
%   data - NxD numeric matrix
%   adjust4UnequalN - if true, categories will be weighted so that rare categories get the same importance as common categories
%   regularizationLvl - scalar - how heavily to weight regularization (liblinear's default was = 1). Set to eps to almost disable regularization, but it'll suck. Set to 'optimize' to have liblinear find the highest performing regularizationLevel.
%RETURNS:
%   model - a struct as described in the 4 liblinear README files. The LAST feature is the bias/intercept term, which you may wish to remove. This struct will change in form depending on whether you passed 2 categories or more than 2
function [model] = TrainLiblinear (solverType, labels, data, adjust4UnequalN, regularizationLvl)
    assert(isnumeric(solverType) && isscalar(solverType) && any(solverType==[0,1,2,3,5,6,7,11]));
    assert(isnumeric(labels) && isvector(labels));
    assert(isnumeric(data) && size(data, 1) == numel(labels));
    assert((isnumeric(regularizationLvl) && isscalar(regularizationLvl)) || strcmp(regularizationLvl, 'optimize'));
    assert(solverType == 0 || solverType == 2, 'currently optimized regularizationLvl only supported by liblinear for solverType 0 or 2');
    
    [uniqueLabels,~,labelsNum] = unique(labels);
    assert(all(labelsNum == labels)); %only required because otherwise the results of the model will be misinterpreted by the calling function
    counts = CountNumericOccurrences(labelsNum, 1:numel(uniqueLabels));
    
    weightString = ''; %weightstring is probably more fair, but it's unclear
    if adjust4UnequalN
        for i = 1:numel(uniqueLabels)
            if numel(uniqueLabels) == 2
                weightString = [weightString,' -w',num2str(i),' ',num2str(1/(counts(i)/numel(labels)))];
            else
                if counts(i) > 0
                    weightString = [weightString,' -w',num2str(i),' ',num2str(1/((counts(i)/numel(labels))*(numel(labels)/(numel(labels)-counts(i)))))];
                end
            end
        end
    end
    
    if strcmp(regularizationLvl, 'optimize')
        regularizationLvl = train(labelsNum, sparse([data,ones(size(data, 1), 1)]), ['-q -s ',num2str(solverType),' -C -n ',num2str(DetermineNumJavaComputeCores()),weightString]); %appending a bias/intercept term
        regularizationLvl = regularizationLvl(1);
        warning('^untested, unclear what train() is returning');
    end
    
    model = train(labelsNum, sparse([data,ones(size(data, 1), 1)]), ['-q -s ',num2str(solverType),' -c ',num2str(regularizationLvl),' -n ',num2str(DetermineNumJavaComputeCores()),weightString]); %appending a bias/intercept term
    
    assert(~isempty(model)); %if model is empty, liblinear crashed
    assert(model.bias < 0); %I think this is always -1 (aka "ignore me") unless we specify the bias beforehand, which we wouldn't normally do
end