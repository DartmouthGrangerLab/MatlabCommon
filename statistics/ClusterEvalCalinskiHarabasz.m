%Eli Bowen (copied directly from matlab's clustering.evaluation.CalinskiHarabaszEvaluation code to make a standalone function)
%12/17/16
%CalinskiHarabasz cluster criterion / variance ratio criterion
%INPUTS:
%   X - NxD position of each data point
%   clustAssignments - 1D vector (N elements) cluster ID assigned to each datapoint (e.g. a value of 2 indicates a point was assigned to the centroid with mean at the second row of 'centroids')
function [ch] = ClusterEvalCalinskiHarabasz (X, clustAssignments)
    assert(~any(any(isnan(X))), 'X contains NaN values. TODO: code a way to handle this');
    assert(numel(unique(clustAssignments)) > 1, 'Only one cluster has assignments!');
	
    clusts = unique(clustAssignments);
    K = numel(clusts);
    [N,D] = size(X);
    globalMean = mean(X, 1);
    
    centroids = zeros(K, D);
    Ni = zeros(K, 1); %number of points in each cluster
    sumD = zeros(K, 1); %sum of Squared Euclidean
    for i = 1:K
        members = (clustAssignments == i);
        centroids(i,:) = mean(X(members,:), 1);
        Ni(i) = sum(members);
        sumD(i) = sum(pdist2(X(members,:), centroids(i,:)) .^ 2);
    end
    
    %% Within cluster variance
	SSW = sum(sumD, 1);
    
    %% Between cluster variance
	SSB = pdist2(centroids, globalMean) .^ 2;
	SSB = sum(Ni .* SSB);
	ch =(SSB/(K-1)) / (SSW/(N-K));
end