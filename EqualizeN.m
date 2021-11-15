% Eli Bowen
% randomly subsets each category (except the rarest one) so that they all have equal N
% INPUTS:
%   label - 1 x n_datapts (int-valued numeric)
% RETURNS:
%   selectedIdx - 1 x n_returned_datapts (int-valued double)
function [selectedIdx] = EqualizeN (label)
    [uniqueLabel,~,labelNum] = unique(label);

    N = min(CountNumericOccurrences(labelNum, 1:numel(uniqueLabel)));

    % form separate arrays for each category, subset to be of equal length, then recombine
    selectedIdx = zeros(N, numel(uniqueLabel));
    for i = 1 : numel(uniqueLabel)
        categoryIdx = find(labelNum == i);
        selectedIdx(:,i) = categoryIdx(randperm(numel(categoryIdx), N));
    end

    selectedIdx = sort(selectedIdx(:)'); % vectorize, be stable
end