% INPUTS:
%   data          - N x D (numeric)
%   kList         - (OPTIONAL) list of K's to consider. Default is 1:6.
%   clusterMethod - (OPTIONAL) string specifying cluster method, one of 'kmeans', 'linkage', 'gmdistribution'. Default = 'linkage'.
%   verbose       - (OPTIONAL) if 1 then print results to screen. Default = 0.
% RETURNS:
%   evalCH - Calinski Harabasz criterion
%   evalDB - Davies Bouldin criterion
%   evalS  - silhouette criterion
function [evalCH,evalDB,evalS] = ClusterOptimalK(data, kList, clusterMethod, verbose)
    if isempty(kList)
        kList = 2:6;
    end
    if isempty(verbose)
        verbose = 0;
    end
    if isempty(clusterMethod)
        clusterMethod = 'linkage';
    end

    N = size(data, 1);
    D = size(data, 2);
    assert(N >= D);

    evalCH = evalclusters(data, clusterMethod, 'CalinskiHarabasz', 'klist', kList);
    evalDB = evalclusters(data, clusterMethod, 'DaviesBouldin', 'klist', kList);
    evalS  = evalclusters(data, clusterMethod, 'silhouette', 'klist', kList);
    if verbose == 1
        fprintf('Calinski Harabasz score = %f at optimal K of %d\n', evalCH.CriterionValues(evalCH.InspectedK==evalCH.OptimalK), evalCH.OptimalK);
        fprintf('Davies Bouldin score = %f at optimal K of %d\n', evalDB.CriterionValues(evalDB.InspectedK==evalDB.OptimalK), evalDB.OptimalK);
        fprintf('Silhouette score = %f (1 = best) at optimal K of %d\n', evalS.CriterionValues(evalS.InspectedK==evalS.OptimalK), evalS.OptimalK);
    end
end
