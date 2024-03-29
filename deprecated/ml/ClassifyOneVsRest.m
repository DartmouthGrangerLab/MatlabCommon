% deprecated (instead, see ml package)
function [acc,predLabel,score,uniqueLabelOut] = ClassifyOneVsRest(trnData, trnLabel, tstData, tstLabel, classifierType, classifierParams, verbose)
    % params validated in Classify()
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    t = tic();

    [uniqueLabel,~,trnLabelIdx] = unique(trnLabel, 'stable');
    
    tstLabelIdx = tstLabel;
    [r,c] = find(uniqueLabel(:) == tstLabel(:)');
    tstLabelIdx(c) = r;
    % above is faster than below, same result
%     for i = 1 : numel(tstLabel)
%         tstLabelIdx(i) = find(uniqueLabel == tstLabel(i));
%     end

    n_classes = numel(uniqueLabel);
    assert(n_classes > 2); % if 2, just call Classify(); if 1 wtf are you doing
    n_tstpts  = numel(tstLabel);

    acc       = NaN(1, n_classes);
    predLabel = NaN(n_tstpts, n_classes);
    score     = NaN(n_tstpts, 2, n_classes);
    for i = 1 : n_classes
        if nargout() > 2
            [acc(i),predLabel(:,i),temp] = Classify(trnData, (trnLabelIdx == i) + 1, tstData, (tstLabelIdx == i) + 1, classifierType, classifierParams, false);
            if ~isempty(temp)
                score(:,:,i) = temp;
            end
        elseif nargout() > 1 % faster
            [acc(i),predLabel(:,i)]      = Classify(trnData, (trnLabelIdx == i) + 1, tstData, (tstLabelIdx == i) + 1, classifierType, classifierParams, false);
        else % fasterer
            acc(i)                       = Classify(trnData, (trnLabelIdx == i) + 1, tstData, (tstLabelIdx == i) + 1, classifierType, classifierParams, false);
        end
    end

    if nargout() > 3
        uniqueLabelOut = cell(2, n_classes);
        for i = 1 : n_classes
            uniqueLabelOut{1,i} = 'other';
            uniqueLabelOut{2,i} = num2str(uniqueLabel(i));
        end
    end

    if verbose; disp([mfilename(),': ',classifierType,' (n_trn = ',num2str(numel(trnLabelIdx)),', n_tst = ',num2str(numel(tstLabelIdx)),', acc = ',num2str(mean(acc)),') took ',num2str(toc(t)),' s']); end
end