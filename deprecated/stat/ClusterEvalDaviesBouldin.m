% deprecated
function db = ClusterEvalDaviesBouldin(X, clustAssignments)
    assert(~any(any(isnan(X))), 'X contains NaN values. TODO: code a way to handle this');
    assert(numel(unique(clustAssignments)) > 1, 'Only one cluster has assignments!');

    clusts = unique(clustAssignments);
    K = numel(clusts);
    [N,D] = size(X);

    centroids = zeros(K, D);
    aveWithinD = zeros(K, 1);
    for i = 1 : K
        members = (clustAssignments == clusts(i));
        centroids(i,:) = mean(X(members,:), 1);
        aveWithinD(i) = mean(pdist2(X(members,:), centroids(i,:))); % average euclidean distance of each observation to the centroids
    end

    interD = pdist(centroids, 'euclidean'); % euclidean distance

    R = zeros(K, K);
    for i = 1 : K
        for j = i+1:K % j > i
            R(i,j) = (aveWithinD(i)+aveWithinD(j)) / interD((i-1)*(K-i/2)+j-i); %d((I-1)*(M-I/2)+J-I)
        end
    end
    R = R + R';

    RI = max(R, [], 1);
    db = mean(RI);
end