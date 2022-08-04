% Eli Bowen 1/6/2017
% INPUTS
%   data           - n_datapts x n_dims (double)
%   label
%   classifierType - (char) 'lda' | 'svm' (BROKEN) | 'svmjava' | 'svmliblinear' | 'logreg' | 'logregliblinear'
%   verbose        - OPTIONAL (default = true)
% RETURNS
%   primaryAxis - n_dims x 1 (numeric)
function primaryAxis = Classify4DiscrimDim(data, label, classifierType, verbose)
    validateattributes(data, {'numeric','logical'}, {'nonempty','2d','nrows',numel(label)}, 1);
    validateattributes(label, {'numeric','cell'}, {'nonempty','vector'}, 2);
    validateattributes(classifierType, {'char'}, {'nonempty'}, 3);
    assert(numel(unique(label)) == 2);
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = true;
    end

    if isnumeric(label)
        label = strsplit(num2str(label(:)'));
    end
    [uniqueLabels,~,labelNum] = unique(label);
    %TODO: I think below (copied from ClassifyCrossvalidate) is more correct
%     if isnumeric(label)
%         [uniqueLabels,~,labelNum] = unique(label(:)); % get rid of labels with no exemplars;
%         uniqueLabels = strsplit(num2str(uniqueLabels'))'; % need to maintain numeric (not string) order
%         label = strsplit(num2str(labelNum(:)'))';
%     else %cell
%         [uniqueLabels,~,labelNum] = unique(label);
%     end

    if verbose
        disp([num2str(numel(uniqueLabels)),'-class ',classifierType]);
    end
    
    primaryAxis = zeros(size(data, 2), 1); % MUST be before we delete zero-variance dims
        
    variances = var(data, 0, 1); % check for dimensions of zero variance (or learning algs will crash)
    data(:,variances==0) = [];
    
    t = tic();
    if strcmp(classifierType, 'lda')
        counts = CountNumericOccurrences(labelNum, 1:numel(uniqueLabels));
        cost = zeros(2, 2); % code for setting cost only works because this is 2-class problem - otherwise things get more complicated
        cost(1,2) = 1/(counts(1)/numel(label));
        cost(2,1) = 1/(counts(2)/numel(label)); % this appears correct (vs the transpose of this matrix) because it yields TP rates similar for both categories - the other way the smaller category is at chance (and worse than even costs).
        model = fitcdiscr(data, label, 'ClassNames', uniqueLabels, 'Cost', cost, 'discrimType', 'pseudoLinear');
        primaryAxis(variances~=0) = model.Coeffs(1,2).Linear; %corr(model.Coeffs(1,2).Linear,model.Coeffs(2,1).Linear) is exactly -1
    elseif strcmp(classifierType, 'svm')
        counts = CountNumericOccurrences(labelNum, 1:numel(uniqueLabels));
        cost = zeros(2, 2); % code for setting cost only works because this is 2-class problem - otherwise things get more complicated
        cost(1,2) = 1/(counts(1)/numel(label));
        cost(2,1) = 1/(counts(2)/numel(label)); % this appears correct (vs the transpose of this matrix) because it yields TP rates similar for both categories - the other way the smaller category is at chance (and worse than even costs).
        model = fitcsvm(data, label, 'ClassNames', uniqueLabels, 'Cost', cost, 'KernelFunction', 'linear', 'Standardize', false);
        primaryAxis(variances~=0) = model.Beta;
        error('can''t get betas because fitcsvm is solving the dual problem');
    elseif strcmp(classifierType, 'svmjava')
        error('not yet implemented');
    elseif strcmp(classifierType, 'svmliblinear') % L2-regularized SVM using LIBLINEAR
        model = ml.LiblinearTrain(2, labelNum, data, true, 1);
        primaryAxis(variances~=0) = model.w(:,1:end-1)'; % remove bias/intercept term - we just want the direction of the line
    elseif strcmp(classifierType, 'logreg') % non-regularized logistic regression
        model = fitglm(data, labelNum-1, 'Distribution', 'binomial');
        primaryAxis(variances~=0) = model.Coefficients.Estimate(2:end); % first is intercept - we just want the direction of the line
        error('logreg not currently accounting for unequal N as it should');
    elseif strcmp(classifierType, 'logregliblinear') % L2-regularized logistic regression using LIBLINEAR
        model = ml.LiblinearTrain(0, labelNum, data, true, 1);
        primaryAxis(variances~=0) = model.w(:,1:end-1)'; % remove bias/intercept term - we just want the direction of the line
    else
        error('unknown classifierType');
    end
    if verbose
        toc(t)
    end
    
    primaryAxis = primaryAxis(:)'; % consistently return a 1 x D vector
end