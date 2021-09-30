% Eli Bowen
% 9/12/2018
% wrapper designed to simplify and remove the chance of errors when calling liblinear's train() function
% designed to work with liblinear-multicore version 2.43-2
% switched from version 2.20 (still available as a zip) on 9/29/2021
% on windows, I only have the compiler working via visual studio
% note liblinear uses its own RNG, which can't be controlled
% USAGE:
%   model = TrainLiblinear(0, labelNum, data, true, 1);
%   [predLabel,acc,scores] = predict(labelNum, sparse(data), model, '-q');
% INPUTS:
%   solverType - char or numeric, one of:
%       For multi-class classification:
%       0 / 'logreg' -- L2-regularized logistic regression (primal)
%       1 -- L2-regularized L2-loss support vector classification (dual)
%       2 / 'svm' -- L2-regularized L2-loss support vector classification (primal)
%       3 -- L2-regularized L1-loss support vector classification (dual)
%       4 (NOT SUPPORTED YET) -- support vector classification by Crammer and Singer
%       5 -- L1-regularized L2-loss support vector classification
%       6 -- L1-regularized logistic regression
%       7 (MAYBE SUPPORTED) -- L2-regularized logistic regression (dual)
%       For regression:
%       11 -- L2-regularized L2-loss support vector regression (primal)
%       12 (NOT SUPPORTED YET) -- L2-regularized L2-loss support vector regression (dual)
%       13 (NOT SUPPORTED YET) -- L2-regularized L1-loss support vector regression (dual)
%   for outlier detection
%       21 (NOT SUPPORTED YET) -- one-class support vector machine (dual)
%   label - 1 x N (int-valued numeric) vector of category IDs for the data
%   data - N x D (numeric or logical)
%   adjust4UnequalN - scalar (logical) - if true, categories will be weighted so that rare categories get the same importance as common categories
%   regularizationLvl - scalar (numeric) - how heavily to weight regularization (liblinear's default was = 1). Set to eps to almost disable regularization, but it'll suck. Set to 'optimize' to have liblinear find the highest performing regularizationLevel.
% RETURNS:
%   model - a struct as described in the 4 liblinear README files. The LAST feature is the bias/intercept term, which you may wish to remove. This struct will change in form depending on whether you passed 2 categories or more than 2
function [model] = TrainLiblinear (solverType, label, data, adjust4UnequalN, regularizationLvl)
    if ischar(solverType)
        if strcmp(solverType, 'logreg')
            solverType = 0;
        elseif strcmp(solverType, 'svm')
            solverType = 2;
        else
            error('unexpected solverType');
        end
    end
    validateattributes(solverType, {'numeric'}, {'nonempty','scalar','nonnegative','integer'});
    validateattributes(label, {'numeric'}, {'nonempty','vector','positive','integer'});
    validateattributes(data, {'double','logical'}, {'nonempty','2d','nrows',numel(label)});
    validateattributes(adjust4UnequalN, {'numeric','logical'}, {'nonempty','scalar'});
    validateattributes(regularizationLvl, {'numeric','char'}, {'nonempty'});
    assert(any(solverType == [0,1,2,3,5,6,11])); % only ones implemented by the version of the parralel library we use
    if any(solverType == [5,6])
        warning('liblinear-multicore options 5 and 6 were never tested');
    end
    assert((isnumeric(regularizationLvl) && isscalar(regularizationLvl)) || strcmp(regularizationLvl, 'optimize'));
    if islogical(data)
        data = double(data);
    end

    N = numel(label);
    [uniqueLabel,~,labelNum] = unique(label);
    assert(all(labelNum == label)); % only required because otherwise the results of the model will be misinterpreted by the calling function
    counts = CountNumericOccurrences(labelNum, 1:numel(uniqueLabel));

    weightString = ''; % weightstring is probably more fair, but it's unclear
    if adjust4UnequalN
        for i = 1:numel(uniqueLabel)
            if numel(uniqueLabel) == 2
                weightString = [weightString,' -w',num2str(i),' ',num2str(1/(counts(i)/N))];
            else
                if counts(i) > 0
                    weightString = [weightString,' -w',num2str(i),' ',num2str(1/((counts(i)/N)*(N/(N-counts(i)))))];
                end
            end
        end
    end

    if strcmp(regularizationLvl, 'optimize')
        assert(solverType == 0 || solverType == 2, 'currently, optimized regularizationLvl only supported by liblinear for solverType 0 or 2');
        regularizationLvl = train(label, sparse([data,ones(N, 1)]), ['-q -s ',num2str(solverType),' -C -n ',num2str(DetermineNumJavaComputeCores()),weightString]); % appending a bias/intercept term
        regularizationLvl = regularizationLvl(1);
        warning('^untested, unclear what train() is returning');
    end

    % train should be in MatlabCommon/liblinear-multicore - if matlab thinks this is a toolbox function, you need to compile liblinear-multicore
    model = train(label, sparse([data,ones(N, 1)]), ['-q -s ',num2str(solverType),' -c ',num2str(regularizationLvl),' -n ',num2str(DetermineNumJavaComputeCores()),weightString]); % appending a bias/intercept term

    assert(~isempty(model)); % if model is empty, liblinear crashed
    assert(model.bias < 0); % I think this is always -1 (aka "ignore me") unless we specify the bias beforehand, which we wouldn't normally do
end