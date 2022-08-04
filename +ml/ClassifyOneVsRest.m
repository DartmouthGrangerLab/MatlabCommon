% Eli Bowen 10/1/2021
% breaks ml.Classify() into multiple 1-vs-rest classifications
% INPUTS
%   trnData          - n_trnpts x n_dims (numeric or logical)
%   trnLabel         - 1 x n_trnpts (int-valued numeric or cell array of chars)
%   tstData          - n_tstpts x n_dims (numeric or logical)
%   tstLabel         - 1 x n_tstpts (int-valued numeric or cell array of chars)
%   classifierType   - (char) 'lda' | 'svm' | 'svmjava' | 'svmliblinear' | 'logreg' | 'logregliblinear' | 'knn'
%   classifierParams - OPTIONAL (struct) see Classify() for fields
%   verbose          - OPTIONAL scalar (logical) should we print text? (default=false)
% RETURNS
%   acc - scalar (double ranged 0 --> 1) accuracy (mean across folds)
%   predLabel
%   score - n_tstpts x n_classes. 'score(i,j) represents the confidence that data point i is of class j'
%   uniqLabelOut - 2 x n_classes (cellstr)
% see also ml.Classify
function [acc,predLabel,score,uniqLabelOut] = ClassifyOneVsRest(trnData, trnLabel, tstData, tstLabel, classifierType, classifierParams, verbose)
    % params validated in Classify()
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    t = tic();

    [uniqueLabel,~,trnLabelIdx] = unique(trnLabel, 'stable');
    
    tstLabelIdx = tstLabel;
    [r,c] = find(uniqueLabel(:) == tstLabel(:)');
    tstLabelIdx(c) = r;
    % above is faster than below, same result
%     for i = 1 : numel(tstLabel)
%         tstLabelIdx(i) = find(uniqueLabel == tstLabel(i));
%     end

    n_classes = numel(uniqueLabel);
    assert(n_classes > 2); % if 2, just call Classify(); if 1 wtf are you doing
    n_tstpts  = numel(tstLabel);

    acc       = NaN(1, n_classes);
    predLabel = NaN(n_tstpts, n_classes);
    score     = NaN(n_tstpts, 2, n_classes);
    for i = 1 : n_classes
        if nargout() > 2
            [acc(i),predLabel(:,i),temp] = ml.Classify(trnData, (trnLabelIdx == i) + 1, tstData, (tstLabelIdx == i) + 1, classifierType, classifierParams, false);
            if ~isempty(temp)
                score(:,:,i) = temp;
            end
        elseif nargout() > 1 % faster
            [acc(i),predLabel(:,i)]      = ml.Classify(trnData, (trnLabelIdx == i) + 1, tstData, (tstLabelIdx == i) + 1, classifierType, classifierParams, false);
        else % fasterer
            acc(i)                       = ml.Classify(trnData, (trnLabelIdx == i) + 1, tstData, (tstLabelIdx == i) + 1, classifierType, classifierParams, false);
        end
    end

    if nargout() > 3
        uniqLabelOut = cell(2, n_classes);
        for i = 1 : n_classes
            uniqLabelOut{1,i} = 'other';
            uniqLabelOut{2,i} = num2str(uniqueLabel(i));
        end
    end

    if verbose; disp([mfilename(),': ',classifierType,' (n_trn = ',num2str(numel(trnLabelIdx)),', n_tst = ',num2str(numel(tstLabelIdx)),', acc = ',num2str(mean(acc)),') took ',num2str(toc(t)),' s']); end
end