% deprecated (instead, see ml package)
function [acc,predLabel,score,uniqueLabelOut] = ClassifyBinary(trnData, trnLabel, tstData, tstLabel, classifierType, classifierParams, verbose)
    validateattributes(trnData, {'numeric','logical'}, {'nonempty','nrows',numel(trnLabel)}, 1);
    validateattributes(tstData, {'numeric','logical'}, {'nonempty','nrows',numel(tstLabel)}, 3);
    % other params validated in Classify()
    if ~exist('verbose', 'var') || isempty(verbose)
        verbose = false;
    end
    t = tic();

    [uniqueLabel,~,trnLabelIdx] = unique(trnLabel, 'stable');
    
    tstLabelIdx = tstLabel;
    [r,c] = find(uniqueLabel(:) == tstLabel(:)'); % untested may be faster
    tstLabelIdx(c) = r;
    % above is faster than below, same result
%     for i = 1 : numel(tstLabel)
%         tstLabelIdx(i) = find(uniqueLabel == tstLabel(i));
%     end

    n_classes = numel(uniqueLabel);
    assert(n_classes > 2); % just call Classify() if 2, if 1 wtf are you doing

    acc       = NaN(n_classes, n_classes);
    predLabel = cell(n_classes, n_classes);
    score     = cell(n_classes, n_classes);
    for i = 1 : n_classes
        for j = i + 1 : n_classes
            trnKeep = (trnLabelIdx == i | trnLabelIdx == j);
            tstKeep = (tstLabelIdx == i | tstLabelIdx == j);
            if nargout() > 2
                [acc(i,j),predLabel{i,j},score{i,j}] = Classify(trnData(trnKeep,:), (trnLabelIdx(trnKeep) == i) + 1, tstData(tstKeep,:), (tstLabelIdx(tstKeep) == i) + 1, classifierType, classifierParams, false);
            elseif nargout() > 1 % faster
                [acc(i,j),predLabel{i,j}]            = Classify(trnData(trnKeep,:), (trnLabelIdx(trnKeep) == i) + 1, tstData(tstKeep,:), (tstLabelIdx(tstKeep) == i) + 1, classifierType, classifierParams, false);
            else % fasterer
                acc(i,j)                             = Classify(trnData(trnKeep,:), (trnLabelIdx(trnKeep) == i) + 1, tstData(tstKeep,:), (tstLabelIdx(tstKeep) == i) + 1, classifierType, classifierParams, false);
            end
        end
    end

    if nargout() > 3
        uniqueLabelOut = cell(2, n_classes, n_classes);
        for i = 1 : n_classes
            for j = i + 1 : n_classes
                uniqueLabelOut{1,i,j} = num2str(uniqueLabel(j));
                uniqueLabelOut{2,i,j} = num2str(uniqueLabel(i));
            end
        end
    end

    if verbose; disp([mfilename(),': ',classifierType,' (n_trn = ',num2str(numel(trnLabelIdx)),', n_tst = ',num2str(numel(tstLabelIdx)),') took ',num2str(toc(t)),' s']); end
end