% Eli Bowen
% 10/1/2021
% INPUTS:
%   trnData - n_trnpts x n_dims (numeric or logical)
%   trnLabel - 1 x n_trnpts (int-valued numeric or cell array of chars)
%   tstData - n_tstpts x n_dims (numeric or logical)
%   tstLabel - 1 x n_tstpts (int-valued numeric or cell array of chars)
%   classifierType - 'lda', 'svm', 'svmjava', 'svmliblinear', 'logreg', 'logregliblinear', 'knn'
%   classifierParams - OPTIONAL struct
%       .cost - misclassification cost, a KxK matrix where first dim is true label, second dim is predicted label (default: ones(K) - eye(K))
%       .k - for KNN
%       .distance - for KNN. e.g. 'euclidean', 'correlation', 'cosine', 'hamming', ...
%   verbose - OPTIONAL scalar (logical) - should we print text? (default=false)
% RETURNS:
%   acc - scalar (double ranged 0 --> 1) - accuracy (mean across folds)
%   predLabel
%   score - n_tstpts x n_classes. 'score(i,j) represents the confidence that data point i is of class j'
function [acc,predLabel,score] = Classify (trnData, trnLabel, tstData, tstLabel, classifierType, classifierParams, verbose)
    validateattributes(trnData, {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(trnLabel),'ncols',size(tstData, 2)});
    validateattributes(trnLabel, {'numeric'}, {'nonempty','vector'});
    validateattributes(tstData, {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(tstLabel),'ncols',size(trnData, 2)});
    validateattributes(tstLabel, {'numeric'}, {'nonempty','vector'});
    validateattributes(classifierType, {'char'}, {'nonempty'});
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        classifierParams = struct();
    end
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end

    % some algs require labels to be the integers 1:numel(uniqueLabels)
    [uniqueLabel,~,trnLabelNum] = unique(trnLabel); % convert labels into index into uniqueLabels
    
    tstLabelNum = tstLabel;
    [r,c] = find(uniqueLabel(:) == tstLabel(:)'); % untested may be faster
    tstLabelNum(c) = r;
    % above is faster than below, same result
%     for i = 1 : numel(tstLabel)
%         tstLabelNum(i) = find(uniqueLabel == tstLabel(i));
%     end

    cost = [];
    if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
        cost = classifierParams.cost;
    end

    t = tic();
    %% classify
    if strcmp(classifierType, 'lda') % --- lda via matlab ---
        if islogical(trnData) || islogical(tstData)
            trnData = double(trnData);
            tstData = double(tstData);
        end
        if numel(uniqueLabel) == 2 % 2-class lda
            model = fitcdiscr(trnData, trnLabelNum, 'ClassNames', uniqueLabel, 'Cost', cost, 'discrimType', 'pseudoLinear');
        else % multiclass lda
            model = fitcecoc(trnData, trnLabelNum, 'ClassNames', uniqueLabel, 'Cost', cost, 'Learners', templateDiscriminant('discrimType', 'pseudoLinear'), 'Options', statset('UseParallel', true));
        end
        acc = 1 - loss(model, tstData, tstLabelNum, 'LossFun', 'classiferror'); % loss = percent incorrect for each fold on testing data
        [predLabel,~,score] = predict(model, tstData, 'Options', statset('UseParallel', true));
        error('untested');
    elseif strcmp(classifierType, 'svm') % --- svm via matlab ---
        if islogical(trnData) || islogical(tstData)
            trnData = double(trnData);
            tstData = double(tstData);
        end
        if numel(uniqueLabel) == 2 % 2-class svm
            model = fitcsvm(trnData, trnLabelNum, 'ClassNames', uniqueLabel, 'Cost', cost, 'KernelFunction', 'linear', 'Standardize', true);
        else % multiclass svm
            model = fitcecoc(trnData, trnLabelNum, 'ClassNames', uniqueLabel, 'Cost', cost, 'Learners', templateSVM('Standardize', 1, 'KernelFunction', 'linear'), 'Options', statset('UseParallel', true));
        end
        acc = 1 - loss(model, tstData, tstLabelNum, 'LossFun', 'classiferror'); % loss = percent incorrect for each fold on testing data
        [predLabel,~,score] = predict(model, tstData); % no parallel option for ficsvm
        error('untested');
    elseif strcmp(classifierType, 'svmjava') % --- svm via java ---
        error('not yet implemented');
    elseif strcmp(classifierType, 'svmliblinear') % --- svm via liblinear-multicore ---
        doAdjust4UnequalN = true;
        model = TrainLiblinear('svm', trnLabelNum, trnData, doAdjust4UnequalN, 1);
        [predLabel,acc,score,~,~] = LiblinearPredict(model, tstLabelNum, tstData);
    elseif strcmp(classifierType, 'logreg') % --- logistic regression via matlab ---
        error('not yet implemented');
    elseif strcmp(classifierType, 'logregliblinear') % --- logistic regression via liblinear-multicore
        doAdjust4UnequalN = true;
        model = TrainLiblinear('logreg', trnLabelNum, trnData, doAdjust4UnequalN, 1);
        [predLabel,acc,score,~,~] = LiblinearPredict(model, tstLabelNum, tstData);
    elseif strcmp(classifierType, 'knn') % --- knn ---
        [predLabel,score] = ClassifyKNN(classifierParams.k, trnData', tstData', trnLabelNum, classifierParams.distance);
        acc = sum(predLabel == tstLabelNum) / numel(tstLabelNum);
        % for knn, score is the "strength" of the classification
    end

    %% finalize predLabel
    predLabel = uniqueLabel(predLabel); % convert back from idx into uniqueLabel to labels as they were provided in the input

    if verbose; disp([classifierType,' took ',num2str(toc(t)),' s']); end
end