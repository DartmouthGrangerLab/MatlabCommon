% deprecated
function [purity,purity2] = Purity (clustMem, categoryLabels)
    uniqueClustMem = unique(clustMem);
    N = numel(clustMem);
    K = numel(uniqueClustMem);
    
    %% the basic purity equation
    temp = zeros(K, 1);
    tempCounts = zeros(K, 1);
    for i = 1:K
        clustIdxs = (clustMem==uniqueClustMem(i));
        temp(i) = max(CountNumericOccurrences(categoryLabels(clustIdxs)));
        tempCounts(i) = sum(clustIdxs);
    end
    purity = sum(temp) / N;
    purity2 = mean(temp ./ tempCounts);
end
