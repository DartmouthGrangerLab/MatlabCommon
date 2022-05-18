% Eli Bowen 12/17/16 (copied directly from matlab's clustering.evaluation.CalinskiHarabaszEvaluation code to make a standalone function)
% CalinskiHarabasz cluster criterion / variance ratio criterion
% this measure uses Euclidean distance, and is best used when clusters are relatively spherical (if you care)
% higher is better, range is (0,Inf)
% This is roughly identical to the anova F-test (https://en.wikipedia.org/wiki/F-test)
% When Rick says do a "within vs between cluster" test, this is it. Silhouette coefficient will also suffice, and is more flexible.
% INPUTS
%   X - N x D position of each data point
%   clustAssignments - 1D vector (N elements) cluster ID assigned to each datapoint (e.g. a value of 2 indicates a point was assigned to the centroid with mean at the second row of 'centroids')
% RETURNS
%   ch
function ch = ClusterEvalCalinskiHarabasz(X, clustAssignments)
    validateattributes(X,                {'numeric'}, {}, 'ClusterEvalCalinskiHarabasz', 'X', 1);
    validateattributes(clustAssignments, {'numeric'}, {'vector','integer','positive'}, 'ClusterEvalCalinskiHarabasz', 'clustAssignments', 2);
    assert(size(X, 1) == numel(clustAssignments));
    assert(~any(isnan(X(:))), 'X contains NaN values. TODO: code a way to handle this');
    if numel(unique(clustAssignments)) == 1
        ch = NaN; % only one cluster has assignments!
        return
    end

    [clusts,~,clustIdx] = unique(clustAssignments);
    K = numel(clusts);
    [N,D] = size(X);
    globalMean = mean(X, 1);

    centroids = zeros(K, D);
    Ni = zeros(K, 1); % number of points in each cluster
    sumD = zeros(K, 1); % sum of squared euclidean
    for i = 1:K
        members = (clustIdx == i);
        centroids(i,:) = mean(X(members,:), 1);
        Ni(i) = sum(members);
        sumD(i) = sum(pdist2(X(members,:), centroids(i,:)) .^ 2);
    end

    if sum(Ni > 1) < 2
        ch = NaN; % only one cluster has >1 assignment
        return
    end

    %% within cluster variance
	SSW = sum(sumD(Ni>1)); % Eli: removing 1-point clusters since their within-cluster variance is undefined

    %% between cluster variance
	SSB = pdist2(centroids, globalMean) .^ 2;
	SSB = sum(Ni(Ni>1) .* SSB(Ni>1)); % Eli: removing 1-point clusters since their within-cluster variance is undefined
    K = K - sum(Ni==1); % Eli: removing 1-point clusters since their within-cluster variance is undefined
	ch = (SSB/(K-1)) / (SSW/(N-K));
end