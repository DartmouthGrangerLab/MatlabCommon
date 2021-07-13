% Eli Bowen
% 11/18/16
% if multiclass, it parallelizes itself, otherwise you should call this in a parfor
% NOTE: svm is too slow, so we're using LDA (lots of datapoints, which is when LDA shines anyways)
% INPUTS:
%   data - N x D (numeric)
%   label - 1 x N (int-valued numeric or cell array of chars)
%   nFolds - scalar (numeric) - how many crossvalidation folds (e.g. 10)
%   classifierType - 'lda', 'svm', 'svmliblinear', 'logregliblinear', 'knn'
%   isEvenN - scalar (logical) - if true, will equalize the number of exemplars of each category. Else, will not
%   classifierParams - OPTIONAL struct
%       .cost - misclassification cost, a KxK matrix where first dim is true label, second dim is predicted label (default: ones(K) - eye(K))
%       .K - for KNN
%       .distMeasure - for KNN. e.g. 'euclidean', 'correlation', 'cosine', 'hamming', ...
%   verbose - OPTIONAL scalar (logical) - should we print text? (default=true)
% RETURNS:
%   acc - scalar double ranged 0 --> 1 - accuracy (mean across folds)
%   predLabel
%   scores - N x nClasses. 'score(i,j) represents the confidence that data point i is of class j'
%   label - only useful if isEvenN==true - your input labels, reordered + subsetted to correspond 1:1 with predLabel
%   selectedIdx - only useful if isEvenN==1
%   rocTPR - OPTIONAL
%   rocFPR - OPTIONAL
function [acc,accStdErr,predLabel,scores,label,selectedIdx,rocTPR,rocFPR] = ClassifyCrossvalidate (data, label, nFolds, classifierType, isEvenN, classifierParams, verbose)
    validateattributes(data, {'numeric'}, {'nonempty','2d'},'nrows',numel(label));
    validateattributes(label, {'numeric','cell'}, {'nonempty','vector'});
    validateattributes(nFolds, {'double'}, {'nonempty','scalar','positive','integer'});
    validateattributes(classifierType, {'char'}, {'nonempty'});
    validateattributes(isEvenN, {'double','logical'}, {'nonempty','scalar'});
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        classifierParams = struct();
    end
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = true;
    end
    
    %% clean up, standardize provided labels
    label = label(:); % label can be either 1 x N or N x 1
    if isnumeric(label)
        numericInLabels = true;
        [uniqueLabels,~,labelNum] = unique(label); % get rid of labels with no exemplars;
        uniqueLabels = strsplit(num2str(uniqueLabels'))'; % need to maintain numeric (not string) order
        label = strsplit(num2str(labelNum(:)'))';
        % above LINE is same as below but WAY (>5x) faster
%         label = cell(numel(labelNum), 1);
%         for i = 1:numel(labelNum)
%             label{i} = num2str(labelNum(i));
%         end
        uniqueLabelsNum = cellfun(@str2num, uniqueLabels); %for later
    else % cell
        numericInLabels = false;
        [uniqueLabels,~,labelNum] = unique(label);
        % above is same as below but WAY (>5x) faster
%         uniqueLabels = unique(label);
%         labelNum = zeros(numel(label), 1);
%         for i = 1:numel(label)
%             labelNum(i) = StringFind(uniqueLabels, label{i}, true);
%         end
    end
    
    if verbose
        disp([num2str(numel(uniqueLabels)),'-class ',classifierType]);
    end
    
    %% equalize N
    if isEvenN
        counts = CountNumericOccurrences(labelNum);
        % form separate arrays for each category, subset to be of equal length, then recombine
        selectedIdx = [];
        for i = 1:numel(uniqueLabels)
            categoryIdx = find(labelNum == i);
            categoryIdx = categoryIdx(randperm(numel(categoryIdx), min(counts)));
            selectedIdx = [selectedIdx;categoryIdx]; %recombine
        end
        data = data(selectedIdx,:);
        label = label(selectedIdx);
        labelNum = labelNum(selectedIdx);
        disp(['subsetting to equal N of ',num2str(min(counts)),', total is now ',num2str(numel(selectedIdx)),' datapoints']);
        clearvars counts categoryIdx;
    else
        selectedIdx = 1:size(data, 1);
    end
    
    %% remove dimensions of zero variance (or learning algs will crash)
    variances = var(data, 0, 1);
    assert(~all(variances==0));
    data(:,variances==0) = [];
    
    %% prepare variables
    if verbose
        disp(uniqueLabels(:)');
    end
    if contains(classifierType, 'liblinear')
        accs = zeros(nFolds, 3); % [accuracy, MSE, squared correlation coeff]
        predLabel = zeros(numel(label), 1);
        if numel(uniqueLabels) == 2 % this is some libsvm bull fucking shit
            scores = zeros(numel(label), 1);
        else
            scores = zeros(numel(label), numel(uniqueLabels));
        end
        % must implement our own crossvalidation, because liblinear's random number generator can't be seeded
        [trainIndices,testIndices] = CrossvalidationKFold(labelNum, nFolds, true); % fitcecoc is random so we'll be random too
    else
        accs = zeros(nFolds, 1);
    end
    
    %% classify
    if strcmp(classifierType, 'lda')
        if numel(uniqueLabels) == 2 %two class LDA
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcdiscr(data, label, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', nFolds, 'Cost', classifierParams.cost);
            else
                models = fitcdiscr(data, label, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', nFolds, 'discrimType', 'pseudoLinear');
            end
        else %multiclass LDA
            template = templateDiscriminant('discrimType', 'pseudoLinear');
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcecoc(data, label, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', nFolds, 'Cost', classifierParams.cost);
            else
                models = fitcecoc(data, label, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', nFolds);
            end
        end
    elseif strcmp(classifierType, 'svm')
        if numel(uniqueLabels) == 2 %two class SVM
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcsvm(data, label, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', nFolds, 'KernelFunction', 'linear', 'Standardize', true, 'Cost', classifierParams.cost);
            else
                models = fitcsvm(data, label, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'KFold', nFolds, 'KernelFunction', 'linear', 'Standardize', true);
            end
        else % multiclass SVM
            template = templateSVM('Standardize', 1, 'KernelFunction', 'linear');
            if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
                models = fitcecoc(data, label, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', nFolds, 'Cost', classifierParams.cost);
            else
                models = fitcecoc(data, label, 'Learners', template, 'CrossVal', 'on', 'ClassNames', uniqueLabels, 'Options', statset('UseParallel',1), 'KFold', nFolds);
            end
        end
    elseif strcmp(classifierType, 'svmjava') % SVM via java
        error('TODO if we care');
%         import matlabclusternetworkjavahelper.*;
%         helper = matlabclusternetworkjavahelper.Logistic(??, ???);
%         helper.Train(double[][] data, int[] label, SolverType solver);
    elseif strcmp(classifierType, 'svmliblinear') % SVM via liblinear-multicore
        if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
            error('not yet implemented: pass cost into TrainLiblinear()');
        end
%         acc = train(label, data, ['-v ',num2str(nFolds),' -s 1 -n ',num2str(DetermineNumJavaComputeCores())]); %dual
%         acc = train(label, data, ['-v ',num2str(nFolds),' -s 2 -wi ',?,' -n ',num2str(DetermineNumJavaComputeCores())]); %primal
%         %when liblinear's parallel version releases matlab wrappers, we can use -n too
%         model = train(labelNum, data, ['-v ',num2str(nFolds),' -s 1 -n ',num2str(DetermineNumJavaComputeCores())]); %dual
%         [predict_label,accuracy,dec_values] = predict(label, data, model);
        for fold = 1:nFolds
            % with automatic regularization selection
%             model = TrainLiblinear(2, labelNum(trainIndices{fold}), data(trainIndices{fold},:), true, 'optimize');
% %             params = train(labelNum(trainIndices{fold}), sparse(data(trainIndices{fold},:)), ['-q -s 2 -C -n ',num2str(DetermineNumJavaComputeCores()),weightString]);
% %             model = train(labelNum(trainIndices{fold}), sparse(data(trainIndices{fold},:)), ['-q -s 2 -c ',num2str(params(1)),' -n ',num2str(DetermineNumJavaComputeCores()),weightString]);
            % much faster, default regularization
            model = TrainLiblinear(2, labelNum(trainIndices{fold}), data(trainIndices{fold},:), true, 1);
%             model = train(labelNum(trainIndices{fold}), sparse(data(trainIndices{fold},:)), ['-q -s 2 -n ',num2str(DetermineNumJavaComputeCores()),weightString]);
            [predLabel(testIndices{fold}),accs(fold,:),scores(testIndices{fold},:)] = predict(labelNum(testIndices{fold}), sparse(data(testIndices{fold},:)), model, '-q');
        end
    elseif strcmp(classifierType, 'logregliblinear') % logistic regression via liblinear-multicore
        if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
            error('not yet implemented: pass cost into TrainLiblinear()');
        end
        for fold = 1:nFolds
            % with automatic regularization selection
%             model = TrainLiblinear(0, labelNum(trainIndices{fold}), data(trainIndices{fold},:), true, 'optimize');
            % much faster, default regularization
            model = TrainLiblinear(0, labelNum(trainIndices{fold}), data(trainIndices{fold},:), true, 1);
            [predLabel(testIndices{fold}),accs(fold,:),scores(testIndices{fold},:)] = predict(labelNum(testIndices{fold}), sparse(data(testIndices{fold},:)), model, '-q');
        end
        warning('TODO: this option not yet validated! all i did was change the TrainLiblinear param from 2 to 0');
    elseif strcmp(classifierType, 'knn') %KNN
        if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
            models = crossval(fitcknn(data, label, 'ClassNames', uniqueLabels, 'NumNeighbors', classifierParams.K, 'Distance', classifierParams.distMeasure, 'Cost', classifierParams.cost), 'KFold', nFolds);
        else
            models = crossval(fitcknn(data, label, 'ClassNames', uniqueLabels, 'NumNeighbors', classifierParams.K, 'Distance', classifierParams.distMeasure), 'KFold', nFolds);
        end
        % below code is a different way of doing things, but it's rather unusual
%         template = templateKNN('Standardize', 1, 'NumNeighbors', classifierParams.K);
%         if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
%             models = fitcecoc(data, label, 'ClassNames', uniqueLabels, 'Learners', template, 'CrossVal', 'on', 'Options', statset('UseParallel', 1), 'Cost', cost, 'KFold', nFolds);
%         else
%             models = fitcecoc(data, label, 'ClassNames', uniqueLabels, 'Learners', template, 'CrossVal', 'on', 'Options', statset('UseParallel', 1), 'KFold', nFolds);
%         end
    else
        error('unknown classifierType');
    end
    
    %% finalize acc and accStdErr
    if contains(classifierType, 'liblinear')
        accs(:,1) = accs(:,1) ./ 100; %accs(fold,:) is [accuracy,MSE,R^2]
    else
        for fold = 1:nFolds
            accs(fold) = 1 - kfoldLoss(models, 'lossfun', 'classiferror', 'folds', fold); %percent incorrect for each fold on testing data
        end
    end
    accStdErr = StdErr(accs);
    acc = mean(accs);
    
    %% finalize predLabel and scores
    if nargout > 2 %for efficiency, only get predLabel and scores if necessary
        if contains(classifierType, 'liblinear')
            if numericInLabels
                predLabel = uniqueLabelsNum(predLabel); % predLabel is the same thing as labelNum, which indexes into uniqueLabels, which are string versions of the original input labels
            else
                predLabel = uniqueLabels(predLabel); % convert back to strings. predLabel is the same thing as labelNum - they index into uniqueLabels
            end
        else
            [predLabel,scores] = kfoldPredict(models);
            if numericInLabels
                predLabel = uniqueLabelsNum(cellfun(@str2num, predLabel)); % each predLabel is a string version of labelNum, which indexes into uniqueLabels, which are string versions of the original input labels
            end
        end
    end
    
    %% ROC
    rocTPR = [];
    rocFPR = [];
    if nargout > 5 && numel(uniqueLabels) == 2
        trueWide = zeros(numel(label), 2); % binary version of the labels, in wide/orthogonal format
        for i = 1:numel(label)
            trueWide(i,labelNum) = 1;
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