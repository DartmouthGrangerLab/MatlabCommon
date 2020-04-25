%Eli Bowen
%11/18/16
%if multiclass, it parallelizes itself, otherwise you should call this in a parfor
%NOTE: svm is too slow, so we're using LDA (lots of datapoints, which is when LDA shines anyways)
%INPUTS:
%   data - NxD numeric
%   labels - Nx1 numeric vector
%   numFolds - how many crossvalidation folds (e.g. 10)
%   classifierType - 'lda', 'svm', 'svmliblinear', 'logregliblinear', 'knn'
%   evenN - if true, will equalize the number of exemplars of each category. Else, will not
%   classifierParams - OPTIONAL struct
%       .cost - misclassification cost, a KxK matrix where first dim is true label, second dim is predicted label (default: ones(K) - eye(K))
%       .K - for KNN
%       .distMeasure - for KNN. e.g. 'euclidean', 'correlation', 'cosine', 'hamming', ...
%   verbose - OPTIONAL (default=true)
%RETURNS:
%   acc - scalar double ranged 0 --> 1 - accuracy (mean across folds)
%   predLabels
%   scores - Nx#classes. 'score(i,j) represents the confidence that data point i is of class j'
%   labels - only useful if evenN==true - your input labels, reordered + subsetted to correspond 1:1 with predLabels
%   selectedIdx - only useful if evenN==1
%   rocTPR - OPTIONAL
%   rocFPR - OPTIONAL
function [acc,accStdErr,predLabels,scores,labels,selectedIdx,rocTPR,rocFPR] = ClassifyCrossvalidate (data, labels, numFolds, classifierType, evenN, classifierParams, verbose)
    validateattributes(data, {'numeric'}, {'nonempty','2d'});
    validateattributes(labels, {'numeric','cell'}, {'nonempty','vector'});
    validateattributes(numFolds, {'double'}, {'nonempty','scalar','positive','integer'});
    validateattributes(classifierType, {'char'}, {'nonempty'});
    validateattributes(evenN, {'double','logical'}, {'nonempty','scalar'});
    assert(size(data, 1) == numel(labels));
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        classifierParams = struct();
    end
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = true;
    end
    
    %% clean up, standardize provided labels
    labels = labels(:);
    if isnumeric(labels)
        numericInLabels = true;
        [uniqueLabels,~,labelsNum] = unique(labels); %get rid of labels with no exemplars;
        uniqueLabels = strsplit(num2str(uniqueLabels'))'; %need to maintain numeric (not string) order
        labels = strsplit(num2str(labelsNum(:)'))';
        %above LINE is same as below but WAY (>5x) faster
%         labels = cell(numel(labelsNum), 1);
%         for i = 1:numel(labelsNum)
%             labels{i} = num2str(labelsNum(i));
%         end
    else %cell
        numericInLabels = false;
        [uniqueLabels,~,labelsNum] = unique(labels);
        %above is same as below but WAY (>5x) faster
%         uniqueLabels = unique(labels);
%         labelsNum = zeros(numel(labels), 1);
%         for i = 1:numel(labels)
%             labelsNum(i) = StringFind(uniqueLabels, labels{i}, true);
%         end
    end
    
    %% equalize N
    if evenN
        counts = CountNumericOccurrences(labelsNum);
        disp(['subsetting to equal N of ',num2str(min(counts))]);
        %form separate arrays for each category, subset to be of equal length, then recombine
        selectedIdx = [];
        for i = 1:numel(uniqueLabels)
            categoryIdx = find(labelsNum == i);
            categoryIdx = categoryIdx(randperm(numel(categoryIdx), min(counts)));
            selectedIdx = [selectedIdx;categoryIdx]; %recombine
        end
        data = data(selectedIdx,:);
        labels = labels(selectedIdx);
        labelsNum = labelsNum(selectedIdx);
        clearvars counts categoryIdx;
    else
        selectedIdx = 1:size(data, 1);
    end
    
    %% remove dimensions of zero variance (or learning algs will crash)
    variances = var(data, 0, 1);
    data(:,variances==0) = [];
    
    %% prepare variables
    if verbose
        disp(uniqueLabels(:)');
    end
    if contains(classifierType, 'liblinear')
        accs       = zeros(numFolds, 3); %[accuracy, MSE, squared correlation coeff]
        predLabels = zeros(numel(labels), 1);
        if numel(uniqueLabels) == 2 %this is some libsvm bull fucking shit
            scores = zeros(numel(labels), 1);
        else
            scores = zeros(numel(labels), numel(uniqueLabels));
        end
        %must implement our own crossvalidation, because liblinear's random number generator can't be seeded
        [trainIndices,testIndices] = CrossvalidationKFold(labelsNum, numFolds, true); %fitcecoc is random so we'll be random too
    end
    
    %% classify
    if strcmp(classifierType, 'lda')
        if numel(uniqueLabels) == 2
            if verbose
                disp('two-class LDA');
            end
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcdiscr(data, labels, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', numFolds, 'Cost', classifierParams.cost);
            else
                models = fitcdiscr(data, labels, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', numFolds, 'discrimType', 'pseudoLinear');
            end
        else
            if verbose
                disp('multiclass LDA');
            end
            template = templateDiscriminant('discrimType', 'pseudoLinear');
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcecoc(data, labels, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', numFolds, 'Cost', classifierParams.cost);
            else
                models = fitcecoc(data, labels, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', numFolds);
            end
        end
    elseif strcmp(classifierType, 'svm')
        if numel(uniqueLabels) == 2
            if verbose
                disp('two-class SVM');
            end
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcsvm(data, labels, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', numFolds, 'KernelFunction', 'linear', 'Standardize', true, 'Cost', classifierParams.cost);
            else
                models = fitcsvm(data, labels, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', numFolds, 'KernelFunction', 'linear', 'Standardize', true);
            end
        else
            if verbose
                disp('multiclass SVM');
            end
            template = templateSVM('Standardize', 1, 'KernelFunction', 'linear');
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcecoc(data, labels, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', numFolds, 'Cost', classifierParams.cost);
            else
                models = fitcecoc(data, labels, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', numFolds);
            end
        end
    elseif strcmp(classifierType, 'svmjava')
        if verbose
            disp('SVM java');
        end
        error('TODO if we care');
%         import matlabclusternetworkjavahelper.*;
%         helper = matlabclusternetworkjavahelper.Logistic(??, ???);
%         helper.Train(double[][] data, int[] labels, SolverType solver);
    elseif strcmp(classifierType, 'svmliblinear')
        if verbose
            disp('SVM liblinear');
        end
        if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
            error('not yet implemented: pass cost into TrainLiblinear()');
        end
%         acc = train(labels, data, ['-v ',num2str(numFolds),' -s 1 -n ',num2str(DetermineNumJavaComputeCores())]); %dual
%         acc = train(labels, data, ['-v ',num2str(numFolds),' -s 2 -wi ',?,' -n ',num2str(DetermineNumJavaComputeCores())]); %primal
%         %when liblinear's parallel version releases matlab wrappers, we can use -n too
%         model = train(labelsNum, data, ['-v ',num2str(numFolds),' -s 1 -n ',num2str(DetermineNumJavaComputeCores())]); %dual
%         [predict_label,accuracy,dec_values] = predict(labels, data, model);
        for fold = 1:numFolds
            %with automatic regularization selection
%             model = TrainLiblinear(2, labelsNum(trainIndices{fold}), data(trainIndices{fold},:), true, 'optimize');
% %             params = train(labelsNum(trainIndices{fold}), sparse(data(trainIndices{fold},:)), ['-q -s 2 -C -n ',num2str(DetermineNumJavaComputeCores()),weightString]);
% %             model = train(labelsNum(trainIndices{fold}), sparse(data(trainIndices{fold},:)), ['-q -s 2 -c ',num2str(params(1)),' -n ',num2str(DetermineNumJavaComputeCores()),weightString]);
            %much faster, default regularization
            model = TrainLiblinear(2, labelsNum(trainIndices{fold}), data(trainIndices{fold},:), true, 1);
%             model = train(labelsNum(trainIndices{fold}), sparse(data(trainIndices{fold},:)), ['-q -s 2 -n ',num2str(DetermineNumJavaComputeCores()),weightString]);
            [predLabels(testIndices{fold}),accs(fold,:),scores(testIndices{fold},:)] = predict(labelsNum(testIndices{fold}), sparse(data(testIndices{fold},:)), model, '-q');
        end
        warning('off', 'backtrace');
        warning('ClassifyCrossvalidate: it makes a big difference when we add a bias/intercept term. just did that here by switching to TrainLiblinear(), but this code has never been run this way!');
        warning('on', 'backtrace');
    elseif strcmp(classifierType, 'logregliblinear')
        if verbose
            disp('logistic regression liblinear');
        end
        if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
            error('not yet implemented: pass cost into TrainLiblinear()');
        end
        for fold = 1:numFolds
            %with automatic regularization selection
%             model = TrainLiblinear(0, labelsNum(trainIndices{fold}), data(trainIndices{fold},:), true, 'optimize');
            %much faster, default regularization
            model = TrainLiblinear(0, labelsNum(trainIndices{fold}), data(trainIndices{fold},:), true, 1);
            [predLabels(testIndices{fold}),accs(fold,:),scores(testIndices{fold},:)] = predict(labelsNum(testIndices{fold}), sparse(data(testIndices{fold},:)), model, '-q');
        end
        warning('off', 'backtrace');
        warning('TODO: this option not yet validated! all i did was change the TrainLiblinear param from 2 to 0');
        warning('on', 'backtrace');
    elseif strcmp(classifierType, 'knn')
        if verbose
            disp('KNN');
        end
        if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
            models = crossval(fitcknn(data, labels, 'ClassNames', uniqueLabels, 'NumNeighbors', classifierParams.K, 'Distance', classifierParams.distMeasure, 'Cost', classifierParams.cost), 'KFold', numFolds);
        else
            models = crossval(fitcknn(data, labels, 'ClassNames', uniqueLabels, 'NumNeighbors', classifierParams.K, 'Distance', classifierParams.distMeasure), 'KFold', numFolds);
        end
        %below code is a different way of doing things, but it's rather unusual
%         template = templateKNN('Standardize', 1, 'NumNeighbors', classifierParams.K);
%         if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
%             models = fitcecoc(data, labels, 'ClassNames', uniqueLabels, 'Learners', template, 'CrossVal', 'on', 'Options', statset('UseParallel', 1), 'Cost', cost, 'KFold', numFolds);
%         else
%             models = fitcecoc(data, labels, 'ClassNames', uniqueLabels, 'Learners', template, 'CrossVal', 'on', 'Options', statset('UseParallel', 1), 'KFold', numFolds);
%         end
    else
        error('unknown classifierType');
    end
    
    if contains(classifierType, 'liblinear')
        accs(:,1) = accs(:,1) ./ 100; %accs(fold,:) is [accuracy,MSE,R^2]
        if numericInLabels
            uniqueLabelsNum = cellfun(@str2num, uniqueLabels);
            predLabels = uniqueLabelsNum(predLabels); %predLabels are the same thing as labelsNum, which indexes into uniqueLabels, which are string versions of the original input labels
        else
            predLabels = uniqueLabels(predLabels); %convert back to strings. predLabels are the same thing as labelsNum - they index into uniqueLabels
        end
    else
        accs = zeros(numFolds, 1);
        for fold = 1:numFolds
            accs(fold) = 1 - kfoldLoss(models, 'lossfun', 'classiferror', 'folds', fold); %percent incorrect for each fold on testing data
        end
        [predLabels,scores] = kfoldPredict(models);
        if numericInLabels
            uniqueLabelsNum = cellfun(@str2num, uniqueLabels);
            predLabels = uniqueLabelsNum(cellfun(@str2num, predLabels)); %predLabels are string versions of labelsNum, which indexes into uniqueLabels, which are string versions of the original input labels
        end
    end
    accStdErr = StdErr(accs);
    acc = mean(accs);
    
    %ROC
    rocTPR = [];
    rocFPR = [];
    if nargout > 5 && numel(uniqueLabels) == 2
        trueWide = zeros(numel(labels), 2); %binary version of the labels, in wide/orthogonal format
        for i = 1:numel(labels)
            trueWide(i,labelsNum) = 1;
        end
        if contains(classifierType, 'liblinear')
            [rocTPR,rocFPR,~] = roc(trueWide',(scores ./ max(abs(scores)))./2 + 0.5);
        else
            [rocTPR,rocFPR,~] = roc(trueWide',scores');
        end
    end
    if contains(classifierType, 'liblinear') && numel(uniqueLabels) == 2
        scores = [];
    end
end