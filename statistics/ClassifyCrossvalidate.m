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
%   selectedIdxs - only useful if evenN==1
%   rocTPR - OPTIONAL
%   rocFPR - OPTIONAL
function [acc,accStdErr,predLabels,scores,labels,selectedIdxs,rocTPR,rocFPR] = ClassifyCrossvalidate (data, labels, numFolds, classifierType, evenN, classifierParams, verbose)
    validateattributes(data, {'numeric'}, {'nonempty','2d'});
    validateattributes(labels, {'numeric'}, {'nonempty','vector'});
    validateattributes(numFolds, {'double'}, {'nonempty','scalar'});
    validateattributes(classifierType, {'char'}, {'nonempty'});
    validateattributes(evenN, {'double','logical'}, {'nonempty','scalar'});
    assert(size(data, 1) == numel(labels));
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        classifierParams = struct();
    end
    if ~exist('verbose', 'var')
        verbose = true;
    end
    
    if isnumeric(labels)
        numericInLabels = true;
        [uniqueLabels,~,labelsNum] = unique(labels); %get rid of labels with no exemplars;
        uniqueLabels = strsplit(num2str(uniqueLabels'))'; %need to maintain numeric (not string) order
%         labels = cell(numel(labelsNum), 1);
%         for i = 1:numel(labelsNum)
%             labels{i} = num2str(labelsNum(i));
%         end
        labels = strsplit(num2str(labelsNum(:)'))'; %same but 5x faster
    elseif iscell(labels)
        numericInLabels = false;
%         uniqueLabels = unique(labels);
%         labelsNum = zeros(numel(labels), 1);
%         for i = 1:numel(labels)
%             labelsNum(i) = StringFind(uniqueLabels, labels{i}, true);
%         end
        [uniqueLabels,~,labelsNum] = unique(labels); %same thing but WAY faster
    else
        error('invalid param labels');
    end
    if verbose
        disp(uniqueLabels);
    end
    if evenN
        counts = CountNumericOccurrences(labelsNum);
        disp(['subsetting to equal N of ',num2str(min(counts))]);
        %form separate arrays for each category, subset to be of equal length
        categoryIdxs = cell(numel(uniqueLabels), 1);
        parfor i = 1:numel(uniqueLabels)
            categoryIdxs{i} = StringFind(labels, uniqueLabels{i}, 1);
            categoryIdxs{i} = categoryIdxs{i}(randperm(numel(categoryIdxs{i}), min(counts)));
        end
        %recombine
        selectedIdxs = [];
        for i = 1:numel(categoryIdxs)
            selectedIdxs = [selectedIdxs,categoryIdxs{i}];
        end
        data = data(selectedIdxs,:);
        labels = labels(selectedIdxs);
    else
        selectedIdxs = 1:size(data, 1);
    end
    clearvars counts; %just for safety given below line used to exist
%     counts = CountNumericOccurrences(labelsNum);
    
    %remove dimensions of zero variance (or learning algs will crash)
    variances = var(data, 0, 1);
    data(:,variances==0) = [];
    
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
        accs = zeros(numFolds, 3); %[accuracy, MSE, squared correlation coeff]
        predLabels = zeros(numel(labels), 1);
        if numel(uniqueLabels) == 2 %this is some libsvm bull fucking shit
            scores = zeros(numel(labels), 1);
        else
            scores = zeros(numel(labels), numel(uniqueLabels));
        end
        [trainIndices,testIndices] = CrossvalidationKFold(labelsNum, numFolds, true); %fitcecoc is random so we'll be random too
        
%         weightString = '';
        if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
            error('not yet implemented: convert cost to weightString, pass into TrainLiblinear().');
        else
%             for i = 1:numel(counts)
%                 error('I think this should be i not i-1: verify');
%                 if numel(uniqueLabels) == 2
%                     weightString = [weightString,' -w',num2str(i-1),' ',num2str(1/(counts(i)/numel(labels)))];
%                 else
%                     weightString = [weightString,' -w',num2str(i-1),' ',num2str(1/((counts(i)/numel(labels))*(numel(labels)/(numel(labels)-counts(i)))))];
%                 end
%             end
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
            %much faster, no regularization
            model = TrainLiblinear(2, labelsNum(trainIndices{fold}), data(trainIndices{fold},:), true, 1);
%             model = train(labelsNum(trainIndices{fold}), sparse(data(trainIndices{fold},:)), ['-q -s 2 -n ',num2str(DetermineNumJavaComputeCores()),weightString]);
            
            [predLabels(testIndices{fold}),accs(fold,:),scores(testIndices{fold},:)] = predict(labelsNum(testIndices{fold}), sparse(data(testIndices{fold},:)), model, '-q');
        end
        accs(:,1) = accs(:,1) ./ 100; %accs(fold,:) is [accuracy,MSE,R^2]
        if numericInLabels
            uniqueLabelsNum = cellfun(@str2num, uniqueLabels);
            predLabels = uniqueLabelsNum(predLabels); %predLabels are the same thing as labelsNum, which indexes into uniqueLabels, which are string versions of the original input labels
        else
            predLabels = uniqueLabels(predLabels); %convert back to strings. predLabels are the same thing as labelsNum - they index into uniqueLabels
        end
        warning('it makes a big difference when we add a bias/intercept term. just did that here by switching to TrainLiblinear(), but this code has never been run this way!');
    elseif strcmp(classifierType, 'logregliblinear')
        if verbose
            disp('logistic regression liblinear');
        end
        error('TODO: call TrainLiblinear() - should be simple to set up but I dont have a reason to invest in validation');
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
    
    if ~strcmp(classifierType, 'svmliblinear')
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
        if strcmp(classifierType, 'svmliblinear')
            [rocTPR,rocFPR,~] = roc(trueWide',(scores ./ max(abs(scores)))./2 + 0.5);
        else
            [rocTPR,rocFPR,~] = roc(trueWide',scores');
        end
    end
    if strcmp(classifierType, 'svmliblinear') && numel(uniqueLabels) == 2
        scores = [];
    end
end