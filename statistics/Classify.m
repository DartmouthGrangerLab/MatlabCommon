% Eli Bowen
% 10/1/2021
% INPUTS:
%   trnData          - n_trnpts x n_dims (numeric or logical)
%   trnLabel         - 1 x n_trnpts (int-valued numeric or cell array of chars)
%   tstData          - n_tstpts x n_dims (numeric or logical)
%   tstLabel         - 1 x n_tstpts (int-valued numeric or cell array of chars)
%   classifierType   - 'lda', 'svm', 'svmjava', 'svmliblinear', 'logreg', 'logregliblinear', 'knn'
%   classifierParams - OPTIONAL struct
%       .cost        - misclassification cost, a KxK matrix where first dim is true label, second dim is predicted label (default: ones(K) - eye(K))
%       .k           - for KNN
%       .distance    - for KNN. e.g. 'euclidean', 'correlation', 'cosine', 'hamming', ...
%   verbose - OPTIONAL scalar (logical) - should we print text? (default=false)
% RETURNS:
%   acc - scalar (double ranged 0 --> 1) - accuracy (mean across folds)
%   predLabel
%   score - n_tstpts x n_classes. 'score(i,j) represents the confidence that data point i is of class j'
function [acc,predLabel,score] = Classify(trnData, trnLabel, tstData, tstLabel, classifierType, classifierParams, verbose)
    validateattributes(trnData,        {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(trnLabel),'ncols',size(tstData, 2)});
    validateattributes(trnLabel,       'numeric',             {'nonempty','vector'});
    validateattributes(tstData,        {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(tstLabel),'ncols',size(trnData, 2)});
    validateattributes(tstLabel,       'numeric',             {'nonempty','vector'});
    validateattributes(classifierType, 'char',                {'nonempty'});
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        classifierParams = struct('regularization_lvl', 'optimize', 'k', 1, 'distance', 'euclidean');
    end
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    assert((islogical(trnData) && islogical(tstData)) || (~islogical(trnData) && ~islogical(tstData)));

    %% clean up, standardize provided labels
    % some algs require labels to be the integers 1:n_classes
    trnLabel = trnLabel(:); % input label can be either 1 x N or N x 1, below code requires consistency
    tstLabel = tstLabel(:); % input label can be either 1 x N or N x 1, below code requires consistency
    [uniqLabel,~,trnLabelIdx] = unique(trnLabel); % convert labels into index into uniqLabels
    n_classes = numel(uniqLabel);
    
    tstLabelIdx = tstLabel;
    [r,c] = find(uniqLabel(:) == tstLabel(:)'); % untested may be faster
    tstLabelIdx(c) = r;
    % above is faster than below, same result
%     for i = 1 : numel(tstLabel)
%         tstLabelIdx(i) = find(uniqLabel == tstLabel(i));
%     end

    n_trn = numel(trnLabelIdx);
    n_tst = numel(tstLabelIdx);
    
    %% remove dimensions of zero variance (or learning algs will crash)
    variances = var(trnData, 0, 1);
    if any(variances == 0)
        assert(~all(variances == 0));
        trnData(:,variances == 0) = [];
        tstData(:,variances == 0) = [];
    end
    
    %% prepare variables
    cost = [];
    if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
        cost = classifierParams.cost;
    end
    do_parallel = true;
    
    %% print info
    if verbose
        disp([classifierType,'...']);
        disp(uniqLabel(:)');
        if any(variances == 0)
            disp(['removed ',num2str(sum(variances==0)),' dims with zero variance']);
        end
        t = tic();
    end

    %% classify
    score = [];
    if strcmp(classifierType, 'nb') % --- naive bayes via matlab ---
        if islogical(trnData)
            trnData = double(trnData);
            tstData = double(tstData);
        end
        if n_classes == 2 % 2-class lda
            model = fitcnb(trnData, trnLabelIdx, 'ClassNames', uniqLabel, 'Cost', cost);
        else % multiclass lda
            model = fitcecoc(trnData, trnLabelIdx, 'ClassNames', uniqLabel, 'Cost', cost, 'Learners', templateNaiveBayes(), 'Options', statset('UseParallel', do_parallel));
        end
        acc = 1 - loss(model, tstData, tstLabelIdx, 'LossFun', 'classiferror'); % loss = percent incorrect for each fold on testing data
        if nargout > 1 % for efficiency, only get predLabel and scores if necessary
            [predLabel,~,score] = predict(model, tstData, 'Options', statset('UseParallel', do_parallel));
        end
        warning('nb untested');
    elseif strcmp(classifierType, 'nbfast') % --- naive bayes via faster 3rd party lib ---
        if islogical(trnData) || all(trnData(:) == 0 | trnData(:) == 1)
            if islogical(trnData)
                trnData = double(trnData); % can't be single
                tstData = double(tstData); % can't be single
            end
            model = nbBern(trnData', trnLabelIdx(:)');
        else % gaussian dist NOT appropriate for count data! use 'nb' with a better distribution instead!
            model = nbGauss(trnData', trnLabelIdx(:)');
        end
        predLabel = nbPred(model, tstData')';
        acc = sum(predLabel == tstLabelIdx) / n_tst;
    elseif strcmp(classifierType, 'lda') % --- lda via matlab ---
        if islogical(trnData)
            trnData = double(trnData);
            tstData = double(tstData);
        end
        if n_classes == 2 % 2-class lda
            model = fitcdiscr(trnData, trnLabelIdx, 'ClassNames', uniqLabel, 'Cost', cost, 'discrimType', 'pseudoLinear');
        else % multiclass lda
            model = fitcecoc(trnData, trnLabelIdx, 'ClassNames', uniqLabel, 'Cost', cost, 'Learners', templateDiscriminant('discrimType', 'pseudoLinear'), 'Options', statset('UseParallel', do_parallel));
        end
        acc = 1 - loss(model, tstData, tstLabelIdx, 'LossFun', 'classiferror'); % loss = percent incorrect for each fold on testing data
        if nargout > 1 % for efficiency, only get predLabel and scores if necessary
            [predLabel,~,score] = predict(model, tstData, 'Options', statset('UseParallel', do_parallel));
        end
        error('lda untested');
    elseif strcmp(classifierType, 'svm') % --- svm via matlab ---
        if islogical(trnData)
            trnData = double(trnData);
            tstData = double(tstData);
        end
        if n_classes == 2 % 2-class svm
            model = fitcsvm(trnData, trnLabelIdx, 'ClassNames', uniqLabel, 'Cost', cost, 'KernelFunction', 'linear', 'Standardize', true);
        else % multiclass svm
            model = fitcecoc(trnData, trnLabelIdx, 'ClassNames', uniqLabel, 'Cost', cost, 'Learners', templateSVM('Standardize', 1, 'KernelFunction', 'linear'), 'Options', statset('UseParallel', do_parallel));
        end
        acc = 1 - loss(model, tstData, tstLabelIdx, 'LossFun', 'classiferror'); % loss = percent incorrect for each fold on testing data
        if nargout > 1 % for efficiency, only get predLabel and scores if necessary
            [predLabel,~,score] = predict(model, tstData); % no parallel option for ficsvm
        end
    elseif strcmp(classifierType, 'svmjava') % --- svm via java ---
        error('not yet implemented');
    elseif strcmp(classifierType, 'svmliblinear') % --- svm via liblinear-multicore ---
        doAdjust4UnequalN = true;
        model = LiblinearTrain('svm', trnLabelIdx, trnData, doAdjust4UnequalN, classifierParams.regularization_lvl);
        [predLabel,acc,score,~,~] = LiblinearPredict(model, tstLabelIdx, tstData);
    elseif strcmp(classifierType, 'logreg') % --- logistic regression via matlab ---
        error('not yet implemented');
    elseif strcmp(classifierType, 'logregliblinear') % --- logistic regression via liblinear-multicore
        doAdjust4UnequalN = true;
        model = LiblinearTrain('logreg', trnLabelIdx, trnData, doAdjust4UnequalN, classifierParams.regularization_lvl);
        [predLabel,acc,score,~,~] = LiblinearPredict(model, tstLabelIdx, tstData);
    elseif strcmp(classifierType, 'knn') % --- knn ---
        if nargout() > 2 % for efficiency, only calc scores if needed
            [predLabel,score] = ClassifyKNN(classifierParams.k, trnData', tstData', trnLabelIdx, classifierParams.distance);
        else
            predLabel         = ClassifyKNN(classifierParams.k, trnData', tstData', trnLabelIdx, classifierParams.distance);
        end
        acc = sum(predLabel == tstLabelIdx) / n_tst;
        % for knn, score is the "strength" of the classification
    else
        error('unexpected classifierType');
    end

    %% finalize
    acc = gather(acc);
    if nargout > 1 % for efficiency, only get predLabel and scores if necessary
        predLabel = uniqLabel(predLabel); % convert back from idx into uniqLabel to labels as they were provided in the input
    end
    if nargout > 2
        score = gather(score);
    end

    if verbose; disp([mfilename(),': ',num2str(n_classes),'-class ',num2str(size(trnData, 2)),'-dim ',classifierType,' (n_trn = ',num2str(n_trn),', n_tst = ',num2str(n_tst),', acc = ',num2str(acc, 4),') took ',num2str(toc(t)),' s']); end
end