% deprecated (instead, see ml package)
function [acc,predLabel,score] = Classify(trnData, trnLabel, tstData, tstLabel, classifierType, classifierParams, verbose)
    validateattributes(trnData,        {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(trnLabel),'ncols',size(tstData, 2)}, 1);
    validateattributes(trnLabel,       {'numeric'},           {'nonempty','vector'}, 2);
    validateattributes(tstData,        {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(tstLabel),'ncols',size(trnData, 2)}, 3);
    validateattributes(tstLabel,       {'numeric'},           {'nonempty','vector'}, 4);
    validateattributes(classifierType, {'char'},              {'nonempty'}, 5);
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        distribution = 'gauss';
        if islogical(trnData) || all(trnData(:) == 0 | trnData(:) == 1)
            distribution = 'bern';
        end
        classifierParams = struct('regularization_lvl', 'optimize', 'k', 1, 'distance', 'euclidean', 'distribution', distribution,...
            'hidden_sz', 10, 'train_func', 'trainscg', 'perform_func', 'crossentropy',...
            'n_variables_to_sample', 'all', 'method', 'Bag', 'n_learning_cycles', 100);
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
    acc = [];
    score = []; % in case we don't set it below
    if strcmp(classifierType, 'nb') % --- naive bayes via matlab ---
        if islogical(trnData)
            error('ues classifierType=nbfast with logical data; classifierType=nb doesnt support bernoulli distributions');
        end
        model = fitcnb(trnData, trnLabelIdx, 'ClassNames', uniqLabel, 'Cost', cost);
        acc = 1 - loss(model, tstData, tstLabelIdx, 'LossFun', 'classiferror'); % loss = percent incorrect for each fold on testing data
        if nargout > 1 % for efficiency, only get predLabel and scores if necessary
            [predLabel,~,score] = predict(model, tstData, 'Options', statset('UseParallel', do_parallel));
        end
        warning('nb untested');
    elseif strcmp(classifierType, 'nbfast') % --- naive bayes via faster 3rd party lib ---
        if islogical(trnData)
            trnData = double(trnData); % can't be single
            tstData = double(tstData); % can't be single
        end
        if strcmp(classifierParams.distribution, 'bern') % bernoulli, for boolean/binary data
            model = nbBern(trnData', trnLabelIdx(:)');
        elseif strcmp(classifierParams.distribution, 'gauss') % gaussian-distributed data
            model = nbGauss(trnData', trnLabelIdx(:)');
        elseif strcmp(classifierParams.distribution, 'multinomial') % for count data
            model = nbMulti(trnData', trnLabelIdx(:)');
        else
            error('unexpected distribution');
        end
        predLabel = nbPred(model, tstData')';
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
        % for knn, score is the "strength" of the classification
    elseif strcmp(classifierType, 'perceptron') % --- a single perceptron ---
        assert(n_classes == 2, 'classifier type perceptron only runs on 2-class problems');
        model = perceptron();
        model.trainParam.showWindow = 0; % disable gui
        % 'useParallel' and 'useGPU': 'no' is default, can set to 'yes'
        model = train(model, trnData', encode.OneHot(trnLabelIdx, n_classes)', 'CheckpointDelay', 0); % data must be d x n, labels must be one-hot n_classes x n
        predLabel = model(tstData');
        [~,predLabel] = max(predLabel, [], 1); % convert from one-hot to idx
    elseif strcmp(classifierType, 'patternnet') % --- patternnet ---
        model = patternnet(classifierParams.hidden_sz, classifierParams.train_func, classifierParams.perform_func); % default trainFcn = 'trainscg', performFcn = 'crossentropy'
        model.trainParam.showWindow = 0; % disable gui
        model = train(model, trnData', encode.OneHot(trnLabelIdx, n_classes)', 'CheckpointDelay', 0); % data must be d x n, labels must be one-hot
        predLabel = model(tstData');
        [~,predLabel] = max(predLabel, [], 1); % convert from one-hot to idx
        % can also use feedforwardnet for more fine-grained control (patternnet is a kind of feedforwardnet)
    elseif strcmp(classifierType, 'decisiontree') % --- ensemble of decision trees ---
        t = templateTree('NumVariablesToSample', classifierParams.n_variables_to_sample, 'PredictorSelection', 'allsplits', 'Reproducible', true);
        model = fitcensemble(trnData, trnLabelIdx, 'Method', classifierParams.method, 'NumLearningCycles', classifierParams.n_learning_cycles, 'Learners', t); % can also do 'Options', statset(.)
        predLabel = predict(model, tstData);
    else
        error('unexpected classifierType');
    end

    %% finalize
    if isempty(acc)
        acc = sum(predLabel(:) == tstLabelIdx(:)) / n_tst; % for most models
    end
    acc = gather(acc);
    if nargout > 1 % for efficiency, only get predLabel and scores if necessary
        predLabel = uniqLabel(predLabel); % convert back from idx into uniqLabel to labels as they were provided in the input
    end
    if nargout > 2
        score = gather(score);
    end

    Toc(t, verbose, [num2str(n_classes),'-class ',num2str(size(trnData, 2)),'-dim ',classifierType,', n_trn = ',num2str(n_trn),', n_tst = ',num2str(n_tst),', acc = ',num2str(acc, 4)]);
end