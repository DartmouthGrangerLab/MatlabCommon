% Eli Bowen 12/17/16 (copied directly from matlab's clustering.evaluation.DaviesBouldinEvaluation code to make a standalone function)
% DaviesBouldin cluster criterion
% INPUTS
%   X - N x D position of each data point
%   clustAssignments - 1D vector (N elements) cluster ID assigned to each datapoint (e.g. a value of 2 indicates a point was assigned to the centroid with mean at the second row of 'centroids')
% RETURNS
%   db
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