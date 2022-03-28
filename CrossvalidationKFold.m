% Eli Bowen
% implements k-fold cross-validation
% INPUTS:
%   labels   - 1D (numeric) array of label IDs for each datapoint
%   n_folds  - scalar (numeric) number of folds (e.g. 10)
%   beRandom - OPTIONAL (default = false) iff true, datapoints will be randomly shuffled before selection (used to always be false)
% RETURNS:
%   trnIdx - n_folds x 1 (cell array of numeric indexes) indices into labels array (aka positions of datapoints) for training points
%   tstIdx - n_folds x 1 (cell array of numeric indexes) indices into labels array (aka positions of datapoints) for testing points
function [trnIdx,tstIdx] = CrossvalidationKFold(labels, n_folds, beRandom)
    assert(isnumeric(labels) && isvector(labels));
    assert(isnumeric(n_folds) && isscalar(n_folds));
    if ~exist('beRandom', 'var') || isempty(beRandom)
        beRandom = false;
    end

    uniqueLabels = unique(labels);
    trnIdx = cell(n_folds, 1);
    tstIdx = cell(n_folds, 1);
    for fold = 1 : n_folds
        trnIdx{fold} = [];
        tstIdx{fold} = [];
    end
    for k = 1 : numel(uniqueLabels)
        catIdx = find(labels == uniqueLabels(k));
        N = numel(catIdx);
        if beRandom
            catIdx = catIdx(randperm(numel(catIdx)));
        end
        for fold = 1 : n_folds
            trnIdx{fold} = [trnIdx{fold};catIdx(1:ceil((fold-1)*N/n_folds))];
            trnIdx{fold} = [trnIdx{fold};catIdx(ceil(fold*N/n_folds)+1:N)];
            tstIdx{fold} = [tstIdx{fold};catIdx(ceil((fold-1)*N/n_folds+1):ceil(fold*N/n_folds))];
        end
    end
end
