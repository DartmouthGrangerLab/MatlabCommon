%Eli Bowen
%12/17/16
%Silhouette cluster criterion
%see also matlab's silhouette() for plotting or more detailed breakdowns
%INPUTS:
%   X - NxD position of each data point
%   clustAssignments - 1D vector (N elements) cluster ID assigned to each datapoint (e.g. a value of 2 indicates a point was assigned to the centroid with mean at the second row of 'centroids')
%   distMeasure - OPTIONAL (default = 'Euclidean') - any valid input to matlab's silhouette (e.g. 'Euclidean', 'cosine', 'correlation')
function [s] = ClusterEvalSilhouette (X, clustAssignments, distMeasure)
    assert(isvector(clustAssignments) && size(X, 1) == numel(clustAssignments));
    if ~exist('distMeasure', 'var') || isempty(distMeasure)
        distMeasure = 'Euclidean';
    end
    
    s = mean(silhouette(X, clustAssignments, distMeasure), 'omitnan');
    %^ will still produce NaN if all coefficients are NaN (e.g. if there's only one category in clustAssignments, or only one nonzero dimension in the data)
    %but omitnan is useful because single-datapoint clusters return NaN - other clusters may still be good to go.
end
