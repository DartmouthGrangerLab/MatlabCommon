% deprecated
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

    %% Within cluster variance
	SSW = sum(sumD(Ni>1)); % Eli: removing 1-point clusters since their within-cluster variance is undefined

    %% Between cluster variance
	SSB = pdist2(centroids, globalMean) .^ 2;
	SSB = sum(Ni(Ni>1) .* SSB(Ni>1)); % Eli: removing 1-point clusters since their within-cluster variance is undefined
    K = K - sum(Ni==1); % Eli: removing 1-point clusters since their within-cluster variance is undefined
	ch = (SSB/(K-1)) / (SSW/(N-K));
end