% Eli Bowen 3/31/2018
% INPUTS
%   clustMem      - n x 1 (int-valued numeric)
%   categoryLabel - n x 1 (int-valued numeric)
% RETURNS
%   purity - the official definition of purity from:
%       https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-clustering-1.html
%       https://stats.stackexchange.com/questions/95731/how-to-calculate-purity
%   purity2 - weights each cluster equally, rather than weighting by number of cluster members
function [purity,purity2] = Purity(clustMem, categoryLabel)
    uniqueClustMem = unique(clustMem);
    N = numel(clustMem);
    K = numel(uniqueClustMem);

    temp = zeros(K, 1);
    tempCounts = zeros(K, 1);
    for i = 1 : K
        clustMsk = (clustMem == uniqueClustMem(i));
        temp(i) = max(CountNumericOccurrences(categoryLabel(clustMsk)));
        tempCounts(i) = sum(clustMsk);
    end
    purity = sum(temp) / N;
    purity2 = mean(temp ./ tempCounts);
end
