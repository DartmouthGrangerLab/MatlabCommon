% deprecated (instead, see ml package)
function [acc,predLabel] = ClassifyHold1Out(data, label, classifierType, classifierParams, verbose)
    validateattributes(data,           {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(label)}, 1);
    validateattributes(label,          {'numeric'},           {'nonempty','vector'}, 2);
    validateattributes(classifierType, {'char'},              {'nonempty'}, 3);
    if ~exist('classifierParams', 'var') || isempty(classifierParams)
        classifierParams = struct('regularization_lvl', 'optimize', 'k', 1, 'distance', 'euclidean');
    end
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end

    %% clean up, standardize provided labels
    % some algs require labels to be the integers 1:numel(uniqueLabels)
    [uniqueLabel,~,labelIdx] = unique(label); % convert labels into index into uniqueLabels
    n_classes = numel(uniqueLabel);
    n_pts = numel(labelIdx);

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
        if any(variances == 0)
            disp(['removed ',num2str(sum(variances==0)),' dims with zero variance']);
        end
        t = tic();
    end

    %% classify
    if strcmp(classifierType, 'knn') % --- knn ---
        predLabel = ClassifyKNNHold1Out(classifierParams.k, data', labelIdx, classifierParams.distance);
        acc = sum(predLabel == labelIdx) / n_pts;
    else
        error('unexpected classifierType');
    end

    %% finalize predLabel
    acc = gather(acc);
    predLabel = uniqueLabel(predLabel); % convert back from idx into uniqueLabel to labels as they were provided in the input

    if verbose; disp([mfilename(),': ',num2str(n_classes),'-class ',num2str(size(data, 2)),'-dim ',classifierType,' (n_pts = ',num2str(n_pts),', acc = ',num2str(acc, 4),') took ',num2str(toc(t)),' s']); end
end