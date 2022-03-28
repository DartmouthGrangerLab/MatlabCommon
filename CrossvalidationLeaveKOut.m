% implements leave-k-out bootstrapped cross-validation
% INPUTS:
%   labels        - 1D array (numeric) label IDs for each datapoint
%   n_validations - scalar (int-valued numeric) number of bootstrapped cross-validations to perform
%   fraction_tst  - OPTIONAL (number between 0 and 1) describing what fraction of the data for each class should be used for testing (DEFAULT = 0.5)
%   beRandom      - scalar (logical) iff true, datapoints will be randomly shuffled before selection (used to always be true)
% RETURNS:
%   trnIdx - n_validations x 1 (cell array of numeric indexes) indices into labels array (aka positions of datapoints) for training points, one cell per validation trial
%   tstIdx - n_validations x 1 (cell array of numeric indexes) indices into labels array (aka positions of datapoints) for testing points, one cell per validation trial
function [trnIdx,tstIdx] = CrossvalidationLeaveKOut(labels, n_validations, fraction_tst, beRandom)
    assert(isnumeric(labels) && isvector(labels));
    assert(isnumeric(n_validations) && isscalar(n_validations));
    if ~exist('fraction_tst','var') || isempty(fraction_tst)
        fraction_tst = 0.5;
    end

    uniqLabels = unique(labels);
    trnIdx = cell(n_validations, 1);
    tstIdx = cell(n_validations, 1);
    for trial = 1 : n_validations
        trnIdx{trial} = [];
        tstIdx{trial} = [];
    end

    for trial = 1 : n_validations
        for k = 1 : numel(uniqLabels)
            catIndices = find(labels == uniqLabels(k));
            n_tst = ceil(numel(catIndices) * fraction_tst); % num test
            n_trn = numel(catIndices) - n_tst; % num train
            if beRandom
                catIndices = catIndices(randperm(numel(catIndices)));
            end

            trnIdx{trial} = vertcat(trnIdx{trial}, catIndices(1:n_trn));

            uniqueTestCount = numel(catIndices(n_trn+1:end));
            if uniqueTestCount >= n_tst
                tstIdx{trial} = vertcat(tstIdx{trial}, catIndices(n_trn+1:n_trn+n_tst));
            else
                tstIdx{trial} = vertcat(tstIdx{trial}, catIndices(end-(n_tst-1):end));
            end
        end
    end
end
