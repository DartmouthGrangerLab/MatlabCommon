% deprecated (instead, see ml package)
function model = LiblinearTrain(solverType, label, data, doAdjust4UnequalN, regularizationLvl)
    if ischar(solverType)
        if strcmp(solverType, 'logreg')
            solverType = 0;
        elseif strcmp(solverType, 'svm')
            solverType = 2;
        else
            error('unexpected solverType');
        end
    end
    validateattributes(solverType,        {'numeric'},           {'nonempty','scalar','nonnegative','integer'}, 1);
    validateattributes(label,             {'numeric'},           {'nonempty','vector','positive','integer'}, 2);
    validateattributes(data,              {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(label)}, 3);
    validateattributes(doAdjust4UnequalN, {'logical'},           {'nonempty','scalar'}, 4);
    validateattributes(regularizationLvl, {'numeric','char'},    {'nonempty'}, 5);
    if any(solverType == 4:10)
        warning('liblinear-multicore options 4 through 10 were never tested');
    end
    assert((isnumeric(regularizationLvl) && isscalar(regularizationLvl)) || strcmp(regularizationLvl, 'optimize'));
    assert(~isa(data, 'gpuArray'), 'liblinear doesn''t have gpu support');

    n_cores = DetermineNumJavaComputeCores();
    if ~any(solverType == [0,1,2,3,5,6,11]) % only ones implemented by the version of the parallel library we use
        n_cores = 1;
    end
    if ispc() % cant get liblinear_multicore to compile for windows properly
        n_cores = 1;
    end
    
    label = label(:); % required orientation...
    N = numel(label);
    [uniqueLabel,~,labelNum] = unique(label);
    assert(all(labelNum == label)); % only required because otherwise the results of the model will be misinterpreted by the calling function
    counts = CountNumericOccurrences(labelNum, 1:numel(uniqueLabel));
    if islogical(data)
        normMin = 0;
        normMax = 1;
    else
        normMin = min(data, [], 1);
        data = data - normMin; % must pre-scale for runtime and accuracy
        normMax = max(data, [], 1);
        data = data ./ normMax; % must pre-scale for runtime and accuracy
    end
    data = double(data);
    data = sparse([data,ones(N, 1)]); % sparse required by the alg, performance is often poor without a col of ones at the end

    weightStr = ''; % using weightStr is probably more fair, but it's unclear
    if doAdjust4UnequalN
        for i = 1 : numel(uniqueLabel)
            if numel(uniqueLabel) == 2
                weightStr = [weightStr,' -w',num2str(i),' ',num2str(N / counts(i))];
            else
                if counts(i) > 0
                    weightStr = [weightStr,' -w',num2str(i),' ',num2str(1 / (counts(i)*(1/(N-counts(i)))))];
                end
            end
        end
    end
    solverTypeStr = num2str(solverType);

    if strcmp(regularizationLvl, 'optimize')
        assert(any(solverType == [0,2,11]), 'currently, optimized regularizationLvl only supported by liblinear for solverType 0, 2, 11');
        if n_cores == 1
            regularizationLvl = train_liblinear(label, data, ['-q -s ',solverTypeStr,' -C -v 5',weightStr]); % appending a bias/intercept term
        else
            regularizationLvl = train_liblinear_multicore(label, data, ['-q -s ',solverTypeStr,' -C -v 5 -m ',num2str(n_cores),weightStr]); % appending a bias/intercept term
        end
        regularizationLvl = regularizationLvl(1); % returns [best_C,best_p,best_score]
    end
    regularizationLvl = num2str(regularizationLvl);

    if n_cores == 1
        model = train_liblinear(label, data, ['-q -s ',solverTypeStr,' -c ',regularizationLvl,weightStr]); % appending a bias/intercept term
    else
        model = train_liblinear_multicore(label, data, ['-q -s ',solverTypeStr,' -c ',regularizationLvl,' -m ',num2str(n_cores),weightStr]); % appending a bias/intercept term
    end

    assert(~isempty(model)); % if model is empty, liblinear crashed
    assert(model.bias < 0); % I think this is always -1 (aka "ignore me") unless we specify the bias beforehand, which we wouldn't normally do

    model.norm_min = normMin;
    model.norm_max = normMax;
end