%Eli Bowen
%3/31/2018
%"purity" is the official definition of purity from:
%https://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-clustering-1.html
%https://stats.stackexchange.com/questions/95731/how-to-calculate-purity
%purity2 weights each cluster equally, rather than weighting by number of cluster members
function [purity,purity2] = Purity (clustMem, categoryLabels)
    uniqueClustMem = unique(clustMem);
    N = numel(clustMem);
    K = numel(uniqueClustMem);
    
    %% the basic purity equation
    temp = zeros(K, 1);
    tempCounts = zeros(K, 1);
    for i = 1:K
        temp(i) = max(CountNumericOccurrences(categoryLabels(clustMem==uniqueClustMem(i))));
        tempCounts(i) = sum(clustMem==uniqueClustMem(i));
    end
    purity = sum(temp) / N;
    purity2 = mean(temp ./ tempCounts);
end
