%Eli Bowen
%1/6/2017
%INPUTS:
%   data - NxD matrix of doubles
%   labels - 
%   classifierType - one of 'svm' (BROKEN), 'svmliblinear', 'lda', 'logreg', 'logregliblinear'
%   verbose - OPTIONAL (default = true)
%RETURNS:
%   primaryAxis - a Dx1 vector
function [primaryAxis] = Classify4DiscrimDim (data, labels, classifierType, verbose)
    assert(numel(unique(labels)) == 2);
    if ~exist('verbose', 'var')
        verbose = true;
    end
    
    if isnumeric(labels)
%         labelsNum = labels;
%         labels = cell(numel(labelsNum), 1);
%         for i = 1:numel(labelsNum)
%             labels{i} = num2str(labelsNum(i));
%         end
        labels = strsplit(num2str(labels(:)'));
    end
    [uniqueLabels,~,labelsNum] = unique(labels);
        
    variances = var(data, 0, 1); %check for dimensions of zero variance (or learning algs will crash)
    primaryAxis = zeros(size(data, 2), 1);
    
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
        model = fitcsvm(data(:,variances~=0), labels, 'ClassNames', uniqueLabels, 'KernelFunction', 'linear', 'Standardize', false, 'Cost', cost);
        primaryAxis(variances~=0) = model.Beta;
        error('can''t get betas because fitcsvm is solving the dual problem');
    elseif strcmp(classifierType, 'svmliblinear') %L2-regularized SVM using LIBLINEAR
        if verbose
            disp('two-class SVM liblinear');
        end
        model = TrainLiblinear(2, labelsNum, data(:,variances~=0), true, 1);
        primaryAxis(variances~=0) = model.w(:,1:end-1)'; %remove bias/intercept term - we just want the direction of the line
    elseif strcmp(classifierType, 'lda')
        if verbose
            disp('two-class LDA');
        end
        counts = CountNumericOccurrences(labelsNum, 1:numel(uniqueLabels));
        cost = zeros(2, 2); %code for setting cost only works because this is 2-class problem - otherwise things get more complicated
        cost(1,2) = 1/(counts(1)/numel(labels));
        cost(2,1) = 1/(counts(2)/numel(labels)); %this appears correct (vs the transpose of this matrix) because it yields TP rates similar for both categories - the other way the smaller category is at chance (and worse than even costs).
        model = fitcdiscr(data(:,variances~=0), labels, 'ClassNames', uniqueLabels, 'discrimType', 'pseudoLinear', 'Cost', cost);
        primaryAxis(variances~=0) = model.Coeffs(1,2).Linear; %corr(model.Coeffs(1,2).Linear,model.Coeffs(2,1).Linear) is exactly -1
    elseif strcmp(classifierType, 'logreg') %non-regularized logistic regression
        if verbose
            disp('two-class logistic regression');
        end
        model = fitglm(data(:,variances~=0), labelsNum-1, 'Distribution', 'binomial');
        primaryAxis(variances~=0) = model.Coefficients.Estimate(2:end); %first is intercept - we just want the direction of the line
        error('logreg not currently accounting for unequal N as it should');
    elseif strcmp(classifierType, 'logregliblinear') %L2-regularized logistic regression using LIBLINEAR
        if verbose
            disp('two-class logistic regression liblinear');
        end
        model = TrainLiblinear(0, labelsNum, data(:,variances~=0), true, 1);
        primaryAxis(variances~=0) = model.w(:,1:end-1)'; %remove bias/intercept term - we just want the direction of the line
%         clustMem = predict(labelsNum, sparse(data(:,variances~=0),ones(size(data, 1), 1)]), model, '-q');
    else
        error('invalid classifierType');
    end
    if verbose
        toc(time)
    end
    
    primaryAxis = primaryAxis(:)'; %consistently return a Dx1 vector
end
