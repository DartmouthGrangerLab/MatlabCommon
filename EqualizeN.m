% Eli Bowen
% randomly subsets each category (except the rarest one) so that they all have equal N
% INPUTS:
%   label - 1 x n_datapts (int-valued numeric)
%   n     - OPTIONAL scalar (int-valued numeric) number of items per class (if not specified, will use as many as possible)
% RETURNS:
%   selectedIdx - 1 x n_returned_datapts (int-valued double)
function [selectedIdx] = EqualizeN(label, n)
    validateattributes(label, 'numeric', {'integer'});

    [uniqueLabel,~,labelIdx] = unique(label);

    if ~exist('n', 'var') || isempty(n)
        n = min(CountNumericOccurrences(labelIdx, 1:numel(uniqueLabel)));
    else
        validateattributes(n, 'numeric', {'scalar','nonnegative','integer'});
        assert(n <= min(CountNumericOccurrences(labelIdx, 1:numel(uniqueLabel))));
    end

    % form separate arrays for each category, subset to be of equal length, then recombine
    selectedIdx = zeros(n, numel(uniqueLabel));
    for i = 1 : numel(uniqueLabel)
        classIdx = find(labelIdx == i);
        selectedIdx(:,i) = classIdx(randperm(numel(classIdx), n));
    end

    selectedIdx = sort(selectedIdx(:)'); % vectorize, be stable
end