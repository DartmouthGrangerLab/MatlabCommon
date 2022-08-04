% deprecated (instead, see ml package)
function [acc,accStdErr,predLabel,score,uniqueLabelOut] = ClassifyCrossvalidateOneVsRest (data, label, n_folds, classifierType, classifierParams, verbose)
    % params validated in ClassifyCrossvalidate()
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    t = tic();

    [uniqueLabel,~,labelIdx] = unique(label, 'stable');
    n_classes = numel(uniqueLabel);
    assert(n_classes > 2); % if 2, just call Classify(); if 1 wtf are you doing
    n_datapts  = numel(label);

    acc       = NaN(1, n_classes);
    accStdErr = NaN(1, n_classes);
    predLabel = NaN(n_datapts, n_classes);
    score     = NaN(n_datapts, 2, n_classes);
    for i = 1 : n_classes
        if nargout() > 3
            [acc(i),accStdErr(i),predLabel(:,i),temp] = ClassifyCrossvalidate(data, (labelIdx == i) + 1, n_folds, classifierType, false, classifierParams, false);
            if ~isempty(temp)
                score(:,:,i) = temp;
            end
        elseif nargout() > 2 % faster
            [acc(i),accStdErr(i),predLabel(:,i)]      = ClassifyCrossvalidate(data, (labelIdx == i) + 1, n_folds, classifierType, false, classifierParams, false);
        else % fasterer
            [acc(i),accStdErr(i)]                     = ClassifyCrossvalidate(data, (labelIdx == i) + 1, n_folds, classifierType, false, classifierParams, false);
        end
    end

    if nargout() > 4
        uniqueLabelOut = cell(2, n_classes);
        for i = 1 : n_classes
            uniqueLabelOut{1,i} = 'other';
            uniqueLabelOut{2,i} = num2str(uniqueLabel(i));
        end
    end

    if verbose; disp([mfilename(),': ',classifierType,' (n_pts = ',num2str(numel(labelIdx)),', acc = ',num2str(mean(acc)),') took ',num2str(toc(t)),' s']); end
end