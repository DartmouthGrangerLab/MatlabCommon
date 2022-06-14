% Eli Bowen 10/5/2021
% breaks ClassifyCrossvalidate() into multiple 1-vs-1 classifications
% INPUTS:
%   data             - n_datapts x n_dims (numeric or logical)
%   label            - 1 x n_datapts (int-valued numeric or cell array of chars)
%   n_folds          - scalar (int-valued numeric)
%   classifierType   - 'lda', 'svm', 'svmjava', 'svmliblinear', 'logreg', 'logregliblinear', 'knn'
%   classifierParams - OPTIONAL (struct) see ClassifyCrossvalidate() for fields
%   verbose          - OPTIONAL scalar (logical) should we print text? (default=false)
% RETURNS:
%   acc - scalar (double ranged 0 --> 1) accuracy (mean across folds)
%   accStdErr
%   predLabel
%   score - n_datapts x n_classes. 'score(i,j) represents the confidence that data point i is of class j'
%   uniqueLabelOut - 2 x n_classes x n_classes (cell of chars)
function [acc,accStdErr,predLabel,score,uniqueLabelOut] = ClassifyCrossvalidateBinary(data, label, n_folds, classifierType, classifierParams, verbose)
    validateattributes(data, {'numeric','logical'}, {'nonempty','nrows',numel(label)}, 1);
    % other params validated in ClassifyCrossvalidate()
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    t = tic();

    [uniqueLabel,~,labelIdx] = unique(label, 'stable');
    n_classes = numel(uniqueLabel);
    assert(n_classes > 2); % just call Classify() if 2, if 1 wtf are you doing

    acc       = NaN(n_classes, n_classes);
    accStdErr = NaN(n_classes, n_classes);
    predLabel = cell(n_classes, n_classes);
    score     = cell(n_classes, n_classes);
    for i = 1 : n_classes
        for j = i + 1 : n_classes
            keep = (labelIdx == i | labelIdx == j);
            if nargout() > 3
                [acc(i,j),accStdErr(i,j),predLabel{i,j},score{i,j}] = ClassifyCrossvalidate(data(keep,:), (labelIdx(keep) == i) + 1, n_folds, classifierType, false, classifierParams, false);
            elseif nargout() > 2 % faster
                [acc(i,j),accStdErr(i,j),predLabel{i,j}]            = ClassifyCrossvalidate(data(keep,:), (labelIdx(keep) == i) + 1, n_folds, classifierType, false, classifierParams, false);
            else % fasterer
                [acc(i,j),accStdErr(i,j)]                           = ClassifyCrossvalidate(data(keep,:), (labelIdx(keep) == i) + 1, n_folds, classifierType, false, classifierParams, false);
            end
        end
    end

    if nargout() > 4
        uniqueLabelOut = cell(2, n_classes, n_classes);
        for i = 1 : n_classes
            for j = i + 1 : n_classes
                uniqueLabelOut{1,i,j} = num2str(uniqueLabel(j));
                uniqueLabelOut{2,i,j} = num2str(uniqueLabel(i));
            end
        end
    end

    if verbose; disp([mfilename(),': ',classifierType,' (n_pts = ',num2str(numel(labelIdx)),') took ',num2str(toc(t)),' s']); end
end