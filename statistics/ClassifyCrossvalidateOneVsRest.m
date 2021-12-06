% Eli Bowen
% 10/5/2021
% breaks ClassifyCrossvalidate() into multiple 1 vs rest classifications
% INPUTS:
%   data - n_datapts x n_dims (numeric or logical)
%   label - 1 x n_datapts (int-valued numeric or cell array of chars)
%   n_folds - scalar (int-valued numeric)
%   classifierType - 'lda', 'svm', 'svmjava', 'svmliblinear', 'logreg', 'logregliblinear', 'knn'
%   classifierParams OPTIONAL - struct - see ClassifyCrossvalidate() for fields
%   verbose OPTIONAL - scalar (logical) - should we print text? (default=false)
% RETURNS:
%   acc - scalar (double ranged 0 --> 1) - accuracy (mean across folds)
%   accStdErr
%   predLabel
%   score - n_datapts x n_classes. 'score(i,j) represents the confidence that data point i is of class j'
%   uniqueLabelOut - 2 x n_classes (cell of chars)
function [acc,accStdErr,predLabel,score,uniqueLabelOut] = ClassifyCrossvalidateOneVsRest (data, label, n_folds, classifierType, classifierParams, verbose)
    % params validated in ClassifyCrossvalidate()
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    t = tic();

    [uniqueLabel,~,labelIdx] = unique(label, 'stable');
    n_classes = numel(uniqueLabel);
    assert(n_classes > 2); % if 2, just call Classify(); if 1 wtf are you doing
    n_datapts  = numel(label);

    acc       = NaN(1, n_classes);
    accStdErr = NaN(1, n_classes);
    predLabel = NaN(n_datapts, n_classes);
    score     = NaN(n_datapts, 2, n_classes);
    for i = 1 : n_classes
        if nargout() > 3
            [acc(i),accStdErr(i),predLabel(:,i),temp] = ClassifyCrossvalidate(data, (labelIdx == i) + 1, n_folds, classifierType, false, classifierParams, false);
            if ~isempty(temp)
                score(:,:,i) = temp;
            end
        elseif nargout() > 2 % faster
            [acc(i),accStdErr(i),predLabel(:,i)]      = ClassifyCrossvalidate(data, (labelIdx == i) + 1, n_folds, classifierType, false, classifierParams, false);
        else % fasterer
            [acc(i),accStdErr(i)]                     = ClassifyCrossvalidate(data, (labelIdx == i) + 1, n_folds, classifierType, false, classifierParams, false);
        end
    end

    if nargout() > 4
        uniqueLabelOut = cell(2, n_classes);
        for i = 1 : n_classes
            uniqueLabelOut{1,i} = 'other';
            uniqueLabelOut{2,i} = num2str(uniqueLabel(i));
        end
    end

    if verbose; disp([mfilename(),': ',num2str(n_classes),'-class ',classifierType,' (n_pts = ',num2str(numel(labelIdx)),') took ',num2str(toc(t)),' s']); end
end