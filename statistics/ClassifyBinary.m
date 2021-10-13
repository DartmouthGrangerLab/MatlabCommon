% Eli Bowen
% 10/1/2021
% breaks Classify() into multiple 1-vs-1 classifications
% INPUTS:
%   trnData - n_trnpts x n_dims (numeric or logical)
%   trnLabel - 1 x n_trnpts (int-valued numeric or cell array of chars)
%   tstData - n_tstpts x n_dims (numeric or logical)
%   tstLabel - 1 x n_tstpts (int-valued numeric or cell array of chars)
%   classifierType - 'lda', 'svm', 'svmjava', 'svmliblinear', 'logreg', 'logregliblinear', 'knn'
%   classifierParams OPTIONAL - struct - see Classify() for fields
%   verbose OPTIONAL - scalar (logical) - should we print text? (default=false)
% RETURNS:
%   acc - scalar (double ranged 0 --> 1) - accuracy (mean across folds)
%   predLabel
%   score - n_tstpts x n_classes. 'score(i,j) represents the confidence that data point i is of class j'
%   uniqueLabelOut - 2 x n_classes x n_classes (cell of chars)
function [acc,predLabel,score,uniqueLabelOut] = ClassifyBinary (trnData, trnLabel, tstData, tstLabel, classifierType, classifierParams, verbose)
    validateattributes(trnData, {'numeric','logical'}, {'nonempty','nrows',numel(trnLabel)});
    validateattributes(tstData, {'numeric','logical'}, {'nonempty','nrows',numel(tstLabel)});
    % other params validated in Classify()
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    t = tic();

    [uniqueLabel,~,trnLabelNum] = unique(trnLabel, 'stable');
    
    tstLabelNum = tstLabel;
    [r,c] = find(uniqueLabel(:) == tstLabel(:)'); % untested may be faster
    tstLabelNum(c) = r;
    % above is faster than below, same result
%     for i = 1 : numel(tstLabel)
%         tstLabelNum(i) = find(uniqueLabel == tstLabel(i));
%     end

    n_classes = numel(uniqueLabel);
    assert(n_classes > 2); % just call Classify() if 2, if 1 wtf are you doing

    acc       = NaN(n_classes, n_classes);
    predLabel = cell(n_classes, n_classes);
    score     = cell(n_classes, n_classes);
    for i = 1 : n_classes
        for j = i + 1 : n_classes
            trnKeep = (trnLabelNum == i | trnLabelNum == j);
            tstKeep = (tstLabelNum == i | tstLabelNum == j);
            [acc(i,j),predLabel{i,j},score{i,j}] = Classify(trnData(trnKeep,:), (trnLabelNum(trnKeep) == i) + 1, tstData(tstKeep,:), (tstLabelNum(tstKeep) == i) + 1, classifierType, classifierParams, false);
        end
    end

    if nargout() > 3
        uniqueLabelOut = cell(2, n_classes, n_classes);
        for i = 1 : n_classes
            for j = i + 1 : n_classes
                uniqueLabelOut{1,i,j} = num2str(uniqueLabel(j));
                uniqueLabelOut{2,i,j} = num2str(uniqueLabel(i));
            end
        end
    end

    if verbose; disp(['ClassifyBinary took ',num2str(toc(t)),' s']); end
end