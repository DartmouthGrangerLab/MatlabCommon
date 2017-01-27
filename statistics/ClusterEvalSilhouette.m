%Eli Bowen
%12/17/16
%Silhouette cluster criterion
%see also matlab's silhouette() for plotting or more detailed breakdowns
%INPUTS:
%   X - NxD position of each data point
%   clustAssignments - 1D vector (N elements) cluster ID assigned to each datapoint (e.g. a value of 2 indicates a point was assigned to the centroid with mean at the second row of 'centroids')
function [s] = ClusterEvalSilhouette (X, clustAssignments)
    s = mean(silhouette(X, clustAssignments));
end