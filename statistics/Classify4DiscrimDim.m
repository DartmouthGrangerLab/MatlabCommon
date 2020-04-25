%Eli Bowen
%1/6/2017
%INPUTS:
%   data - NxD matrix of doubles
%   labels - 
%   classifierType - one of 'svm' (BROKEN), 'svmliblinear', 'lda', 'logreg', 'logregliblinear'
%   verbose - OPTIONAL (default = true)
%RETURNS:
%   primaryAxis - a 1 x D vector
function [primaryAxis] = Classify4DiscrimDim (data, labels, classifierType, verbose)
    validateattributes(data, {'numeric'}, {'nonempty','2d'});
    validateattributes(labels, {'numeric','cell'}, {'nonempty','vector'});
    validateattributes(classifierType, {'char'}, {'nonempty'});
    assert(size(data, 1) == numel(labels));
    assert(numel(unique(labels)) == 2);
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = true;
    end
    
    if isnumeric(labels)
        labels = strsplit(num2str(labels(:)'));
    end
    [uniqueLabels,~,labelsNum] = unique(labels);
    %TODO: I think below (copied from ClassifyCrossvalidate) is more correct
%     if isnumeric(labels)
%         [uniqueLabels,~,labelsNum] = unique(labels(:)); %get rid of labels with no exemplars;
%         uniqueLabels = strsplit(num2str(uniqueLabels'))'; %need to maintain numeric (not string) order
%         labels = strsplit(num2str(labelsNum(:)'))';
%     else %cell
%         [uniqueLabels,~,labelsNum] = unique(labels);
%     end
    
    primaryAxis = zeros(size(data, 2), 1); %MUST be before we delete zero-variance dims
        
    variances = var(data, 0, 1); %check for dimensions of zero variance (or learning algs will crash)
    data(:,variances==0) = [];
    
    if verbose
        time = tic;
    end
    if strcmp(classifierType, 'svm')
        if verbose
            disp('two-class SVM');
        end
        counts = CountNumericOccurrences(labelsNum, 1:numel(uniqueLabels));
        cost = zeros(2, 2); %code for setting cost only works because this is 2-class problem - otherwise things get more complicated
        cost(1,2) = 1/(counts(1)/numel(labels));
        cost(2,1) = 1/(counts(2)/numel(labels)); %this appears correct (vs the transpose of this matrix) because it yields TP rates similar for both categories - the other way the smaller category is at chance (and worse than even costs).
        model = fitcsvm(data, labels, 'ClassNames', uniqueLabels, 'KernelFunction', 'linear', 'Standardize', false, 'Cost', cost);
        primaryAxis(variances~=0) = model.Beta;
        error('can''t get betas because fitcsvm is solving the dual problem');
    elseif strcmp(classifierType, 'svmliblinear') %L2-regularized SVM using LIBLINEAR
        if verbose
            disp('two-class SVM liblinear');
        end
        model = TrainLiblinear(2, labelsNum, data, true, 1);
        primaryAxis(variances~=0) = model.w(:,1:end-1)'; %remove bias/intercept term - we just want the direction of the line
    elseif strcmp(classifierType, 'lda')
        if verbose
            disp('two-class LDA');
        end
        counts = CountNumericOccurrences(labelsNum, 1:numel(uniqueLabels));
        cost = zeros(2, 2); %code for setting cost only works because this is 2-class problem - otherwise things get more complicated
        cost(1,2) = 1/(counts(1)/numel(labels));
        cost(2,1) = 1/(counts(2)/numel(labels)); %this appears correct (vs the transpose of this matrix) because it yields TP rates similar for both categories - the other way the smaller category is at chance (and worse than even costs).
        model = fitcdiscr(data, labels, 'ClassNames', uniqueLabels, 'discrimType', 'pseudoLinear', 'Cost', cost);
        primaryAxis(variances~=0) = model.Coeffs(1,2).Linear; %corr(model.Coeffs(1,2).Linear,model.Coeffs(2,1).Linear) is exactly -1
    elseif strcmp(classifierType, 'logreg') %non-regularized logistic regression
        if verbose
            disp('two-class logistic regression');
        end
        model = fitglm(data, labelsNum-1, 'Distribution', 'binomial');
        primaryAxis(variances~=0) = model.Coefficients.Estimate(2:end); %first is intercept - we just want the direction of the line
        error('logreg not currently accounting for unequal N as it should');
    elseif strcmp(classifierType, 'logregliblinear') %L2-regularized logistic regression using LIBLINEAR
        if verbose
            disp('two-class logistic regression liblinear');
        end
        model = TrainLiblinear(0, labelsNum, data, true, 1);
        primaryAxis(variances~=0) = model.w(:,1:end-1)'; %remove bias/intercept term - we just want the direction of the line
    else
        error('unknown classifierType');
    end
    if verbose
        toc(time)
    end
    
    primaryAxis = primaryAxis(:)'; %consistently return a 1 x D vector
end
