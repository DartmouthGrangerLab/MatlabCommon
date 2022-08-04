% deprecated (instead, see ml package)
function [acc,accStdErr,predLabel,score,label,selectedIdx,rocTPR,rocFPR] = ClassifyCrossvalidate(data, label, n_folds, classifierType, doEvenN, classifierParams, verbose)
    validateattributes(data,           {'numeric','logical'}, {'nonempty','2d','nrows',numel(label)}, 1);
    validateattributes(label,          {'numeric','cell'},    {'nonempty','vector'}, 2);
    validateattributes(n_folds,        {'double'},            {'nonempty','scalar','positive','integer','>=',2}, 3);
    validateattributes(classifierType, {'char'},              {'nonempty'}, 4);
    validateattributes(doEvenN,        {'double','logical'},  {'nonempty','scalar'}, 5);
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        classifierParams = struct('regularization_lvl', 'optimize', 'k', 1, 'distance', 'euclidean');
    end
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    
    if islogical(data)
        data = double(data);
    end
    
    if isfield(classifierParams, 'K')
        classifierParams.k = classifierParams.K; % temporary backwards compatability
    end

    %% clean up, standardize provided labels
    % some algs require labels to be the integers 1:n_classes
    label = label(:); % input label can be either 1 x N or N x 1, below code requires consistency
    [uniqueLabel,~,labelIdx] = unique(label); % even if label is numeric, must get rid of labels with no exemplars
    n_classes = numel(uniqueLabel);
    n_pts = numel(labelIdx);
    % above is same as below but WAY (>5x) faster
%     uniqueLabel = unique(label);
%     labelIdx = zeros(numel(label), 1);
%     for i = 1 : numel(label)
%         labelIdx(i) = StringFind(uniqueLabel, label{i}, true);
%     end

%     is_in_label_numeric = isnumeric(label);
%     if is_in_label_numeric
%         uniqueLabel = strsplit(num2str(uniqueLabel'))'; % need to maintain numeric (not string) order
%         label = strsplit(num2str(labelIdx(:)'))';
%         % above LINE is same as below but WAY (>5x) faster
% %         label = cell(numel(labelIdx), 1);
% %         for i = 1:numel(labelIdx)
% %             label{i} = num2str(labelIdx(i));
% %         end
%     end
    
    classNames = 1:n_classes;

    %% equalize N
    if doEvenN
        selectedIdx = EqualizeN(labelIdx);
        data = data(selectedIdx,:);
        label = label(selectedIdx);
        labelIdx = labelIdx(selectedIdx);
        n_pts = numel(labelIdx);
    else
        selectedIdx = 1:size(data, 1);
    end

    %% remove dimensions of zero variance (or learning algs will crash)
    variances = var(data, 0, 1);
    if any(variances == 0)
        assert(~all(variances == 0));
        data(:,variances == 0) = [];
    end
    
    %% print info
    if verbose
        disp([classifierType,'...']);
        disp(uniqueLabel(:)');
        if doEvenN
            disp(['subsetting to equal N of ',num2str(n_pts/n_classes),', total is now ',num2str(n_pts),' datapoints']);
        end
        if any(variances == 0)
            disp(['removed ',num2str(sum(variances==0)),' dims with zero variance']);
        end
        t = tic();
    end

    %% prepare variables
    cost = [];
    if isfield(classifierParams, 'cost') && ~isempty(classifierParams.cost)
        cost = classifierParams.cost;
    end
    accs = zeros(1, n_folds);
    if contains(classifierType, 'liblinear') || strcmp(classifierType, 'nbfast')
        % must implement our own crossvalidation, because liblinear's random number generator can't be seeded
        [trnIdx,tstIdx] = CrossvalidationKFold(labelIdx, n_folds, true); % fitcecoc is random so we'll be random too
    end
    do_parallel = ~isa(data, 'gpuArray');

    %% classify
    score = [];
    if strcmp(classifierType, 'nb') % --- naive bayes via matlab ---
        if n_classes == 2 % 2-class lda
            models = fitcnb(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'CrossVal', 'on', 'KFold', n_folds);
        else % multiclass lda
            models = fitcecoc(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'CrossVal', 'on', 'KFold', n_folds, 'Learners', templateNaiveBayes(), 'Options', statset('UseParallel', do_parallel));
        end
        for fold = 1 : n_folds
            accs(fold) = 1 - kfoldLoss(models, 'lossfun', 'classiferror', 'folds', fold); % percent incorrect for each fold on testing data
        end
        if nargout > 2 % for efficiency, only get predLabel and scores if necessary
            [predLabel,score] = kfoldPredict(models);
            predLabel = cellfun(@str2num, predLabel); % each predLabel is a string version of labelIdx, which indexes into uniqueLabel, which are string versions of the original input labels
        end
        warning('nb untested!');
    elseif strcmp(classifierType, 'nbfast') % --- naive bayes via faster 3rd party lib ---
        predLabel = zeros(size(labelIdx));
        for fold = 1 : n_folds
            if islogical(data) || all(data(:) == 0 | data(:) == 1)
                model = nbBern(data(trnIdx{fold},:)', labelIdx(trnIdx{fold}));
            else % gaussian dist NOT appropriate for count data! use 'nb' with a better distribution instead!
                model = nbGauss(data(trnIdx{fold},:)', labelIdx(trnIdx{fold}));
            end
            predLabel(tstIdx{fold}) = nbPred(model, data(tstIdx{fold},:)');
            accs(fold) = sum(predLabel(tstIdx{fold}) == labelIdx(tstIdx{fold})) / numel(labelIdx(tstIdx{fold}));
        end
    elseif strcmp(classifierType, 'lda') % --- lda via matlab ---
        if n_classes == 2 % 2-class lda
            models = fitcdiscr(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'CrossVal', 'on', 'KFold', n_folds, 'discrimType', 'pseudoLinear');
        else % multiclass lda
            models = fitcecoc(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'CrossVal', 'on', 'KFold', n_folds, 'Learners', templateDiscriminant('discrimType', 'pseudoLinear'), 'Options', statset('UseParallel', do_parallel));
        end
        for fold = 1 : n_folds
            accs(fold) = 1 - kfoldLoss(models, 'lossfun', 'classiferror', 'folds', fold); % percent incorrect for each fold on testing data
        end
        if nargout > 2 % for efficiency, only get predLabel and scores if necessary
            [predLabel,score] = kfoldPredict(models);
            predLabel = cellfun(@str2num, predLabel); % each predLabel is a string version of labelIdx, which indexes into uniqueLabel, which are string versions of the original input labels
        end
    elseif strcmp(classifierType, 'svm') % --- svm via matlab
        if n_classes == 2 % 2-class svm
            models = fitcsvm(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'CrossVal', 'on', 'KFold', n_folds, 'KernelFunction', 'linear', 'Standardize', true);
        else % multiclass svm
            models = fitcecoc(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'CrossVal', 'on', 'KFold', n_folds, 'Learners', templateSVM('Standardize', true, 'KernelFunction', 'linear'), 'Options', statset('UseParallel', do_parallel));
        end
        for fold = 1 : n_folds
            accs(fold) = 1 - kfoldLoss(models, 'lossfun', 'classiferror', 'folds', fold); % percent incorrect for each fold on testing data
        end
        if nargout > 2 % for efficiency, only get predLabel and scores if necessary
            [predLabel,score] = kfoldPredict(models);
            predLabel = cellfun(@str2num, predLabel); % each predLabel is a string version of labelIdx, which indexes into uniqueLabel, which are string versions of the original input labels
        end
    elseif strcmp(classifierType, 'svmjava') % --- svm via java ---
        error('TODO if we care');
%         import matlabclusternetworkjavahelper.*;
%         helper = matlabclusternetworkjavahelper.Logistic(??, ???);
%         helper.Train(double[][] data, int[] label, SolverType solver);
    elseif strcmp(classifierType, 'svmliblinear') % --- svm via liblinear-multicore ---
        assert(isempty(cost), 'not yet implemented: pass cost into TrainLiblinear()');
        predLabel = zeros(size(labelIdx));
        score = NaN(numel(labelIdx), n_classes);
        for fold = 1 : n_folds
            model = LiblinearTrain(2, labelIdx(trnIdx{fold}), data(trnIdx{fold},:), true, classifierParams.regularization_lvl);
            [predLabel(tstIdx{fold}),accs(fold),score(tstIdx{fold},:),~,~] = LiblinearPredict(model, labelIdx(tstIdx{fold}), data(tstIdx{fold},:));
        end
    elseif strcmp(classifierType, 'logreg') % --- logistic regression via matlab ---
        error('not yet implemented');
    elseif strcmp(classifierType, 'logregliblinear') % --- logistic regression via liblinear-multicore ---
        assert(isempty(cost), 'not yet implemented: pass cost into TrainLiblinear()');
        predLabel = zeros(size(labelIdx));
        score = NaN(numel(labelIdx), n_classes);
        for fold = 1 : n_folds
            model = LiblinearTrain(0, labelIdx(trnIdx{fold}), data(trnIdx{fold},:), true, classifierParams.regularization_lvl);
            [predLabel(tstIdx{fold}),accs(fold),score(tstIdx{fold},:),~,~] = LiblinearPredict(model, labelIdx(tstIdx{fold}), data(tstIdx{fold},:));
        end
        warning('TODO: this option not yet validated! all i did was change the TrainLiblinear param from 2 to 0');
    elseif strcmp(classifierType, 'knn') % --- knn ---
        models = crossval(fitcknn(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'NumNeighbors', classifierParams.k, 'Distance', classifierParams.distance), 'KFold', n_folds);
        % below code is a different way of doing things, but it's rather unusual
%         template = templateKNN('Standardize', 1, 'NumNeighbors', classifierParams.k);
%         models = fitcecoc(data, labelIdx, 'ClassNames', classNames, 'Cost', cost, 'KFold', n_folds, 'Learners', template, 'CrossVal', 'on', 'Options', statset('UseParallel', do_parallel));
        for fold = 1 : n_folds
            accs(fold) = 1 - kfoldLoss(models, 'lossfun', 'classiferror', 'folds', fold); % percent incorrect for each fold on testing data
        end
        if nargout > 2 % for efficiency, only get predLabel and scores if necessary
            [predLabel,score] = kfoldPredict(models);
            predLabel = cellfun(@str2num, predLabel); % each predLabel is a string version of labelIdx, which indexes into uniqueLabel, which are string versions of the original input labels
        end
%         predLabel = zeros(size(labelIdx));
%         score = NaN(numel(labelIdx), n_classes);
%         for fold = 1 : n_folds
%             model = LiblinearTrain(0, labelIdx(trnIdx{fold}), data(trnIdx{fold},:), true, classifierParams.regularization_lvl);
%             [predLabel(tstIdx{fold}),accs(fold),score(tstIdx{fold},:),~,~] = LiblinearPredict(model, labelIdx(tstIdx{fold}), data(tstIdx{fold},:));
%             if nargout() > 3 % for efficiency, only calc scores if needed
%                 [predLabel(tstIdx{fold}),score(tstIdx{fold},:)] = ClassifyKNN(classifierParams.k, trnData', tstData', labelIdx(trnIdx{fold}), classifierParams.distance);
%             else
%                 predLabel(tstIdx{fold})                         = ClassifyKNN(classifierParams.k, trnData', tstData', labelIdx(trnIdx{fold}), classifierParams.distance);
%             end
%             accs(fold) = sum(predLabel == labelIdx(tstIdx{fold})) / n_pts;
%         end
    else
        error('unknown classifierType');
    end

    %% finalize outputs
    acc = gather(mean(accs));
    accStdErr = gather(StdErr(accs));
    if nargout > 2 % for efficiency, only get predLabel and scores if necessary
        predLabel = uniqueLabel(predLabel); % convert back to unique labels, which might be strings. predLabel is the same thing as labelIdx - they index into uniqueLabel
        score = gather(score);
    end

    %% ROC
    rocTPR = [];
    rocFPR = [];
    if nargout > 5 && numel(uniqueLabel) == 2
        trueOneHot = zeros(n_pts, 2); % binary version of the labels, in wide/orthogonal format
        for i = 1 : n_pts
            trueOneHot(i,labelIdx) = 1;
        end
        [rocTPR,rocFPR,~] = roc(trueOneHot', score');
    end

    if verbose
        disp([mfilename(),': ',num2str(n_classes),'-class ',num2str(size(data, 2)),'-dim ',classifierType,' (n_pts = ',num2str(n_pts),') took ',num2str(toc(t)),' s']);
    end
end