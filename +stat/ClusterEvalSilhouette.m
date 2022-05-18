% Eli Bowen 12/17/16
% Silhouette cluster criterion
% see also matlab's silhouette() for plotting or more detailed breakdowns
% INPUTS
%   X                - N x D position of each data point
%   clustAssignments - 1D vector (N elements) cluster ID assigned to each datapoint (e.g. a value of 2 indicates a point was assigned to the centroid with mean at the second row of 'centroids')
%   distMeasure      - OPTIONAL (default = 'Euclidean') - any valid input to matlab's silhouette (e.g. 'Euclidean', 'cosine', 'correlation')
% RETURNS
%   s
function s = ClusterEvalSilhouette(X, clustAssignments, distMeasure)
    validateattributes(X,                {'numeric'}, {}, 'ClusterEvalSilhouette', 'X', 1);
    validateattributes(clustAssignments, {'numeric'}, {'vector','integer','positive'}, 'ClusterEvalSilhouette', 'clustAssignments', 2);
    assert(size(X, 1) == numel(clustAssignments));
    if ~exist('distMeasure', 'var') || isempty(distMeasure)
        distMeasure = 'Euclidean';
    end

    % matlab is a tool about measuring these distances between points that aren't whatever it defines as perfect. reproducing their code without the crap:
    if strcmp(distMeasure, 'cosine')
        Xnorm = sqrt(sum(X.^2, 2));
        
        tooSmall = (Xnorm <= eps(max(Xnorm)));
        if any(tooSmall)
            X(tooSmall,:) = [];
            clustAssignments(tooSmall) = [];
            disp(['ClusterEvalSilhouette: removing ',num2str(sum(tooSmall)/numel(tooSmall)*100),'% (',num2str(sum(tooSmall)),') of points for being too small for cosine distance']);
        end
    elseif strcmp(distMeasure, 'correlation')
        Xnorm = X - mean(X, 2);
        Xnorm = sqrt(sum(Xnorm.^2, 2));
        
        tooSmall = (Xnorm <= eps(max(Xnorm)));
        if any(tooSmall)
            X(tooSmall,:) = [];
            clustAssignments(tooSmall) = [];
            disp(['ClusterEvalSilhouette: removing ',num2str(sum(tooSmall)/numel(tooSmall)*100),'% (',num2str(sum(tooSmall)),') of points for being too small for correlation distance']);
        end
    end

%     if ischar(distMeasure)
%         s = mean(FastSilhouette(X, clustAssignments, distMeasure), 'omitnan');
%     else
        s = mean(silhouette(X, clustAssignments, distMeasure), 'omitnan');
%     end
    %^ will still produce NaN if all coefficients are NaN (e.g. if there's only one category in clustAssignments, or only one nonzero dimension in the data)
    %but omitnan is useful because single-datapoint clusters return NaN - other clusters may still be good to go.
end


%copied from matlab's silhouette(), but much more efficient
%ok I haven't yet gotten around to making this faster. def can be many times faster though.
% function [s] = FastSilhouette(X, clustAssignments, distMeasure)
%     % grp2idx sorts a numeric grouping variable in ascending order, and a string grouping variable in order of first occurrence
%     [idx,cnames] = grp2idx(clustAssignments);
% 
%     % Remove NaNs, and get size of the non-missing data
%     N = numel(idx);
%     D = size(X, 2);
%     K = numel(cnames);
%     count = histc(idx(:)', 1:K);
% 
%     % 'cosine' and 'correlation' distances need normalized points
%     if strcmp(distMeasure, 'cosine')
%         Xnorm = sqrt(sum(X.^2, 2));
%         if any(min(Xnorm) <= eps(max(Xnorm)))
%             error(message('stats:silhouette:InappropriateCosDistance'));
%         end
%         X = X ./ Xnorm(:,ones(1, D));
%     elseif strcmp(distMeasure, 'correlation')
%         X = X - repmat(mean(X, 2), 1, D);
%         Xnorm = sqrt(sum(X.^2, 2));
%         if any(min(Xnorm) <= eps(max(Xnorm)))
%             error(message('stats:silhouette:InappropriateCorDistance'));
%         end
%         X = X ./ Xnorm(:,ones(1, D));
%     end
% 
%     % Create a list of members for each cluster
%     mbrs = (repmat(1:K, N, 1) == repmat(idx, 1, K));
% 
%     % Get avg distance from every point to all (other) points in each cluster
%     myinf = zeros(1, 1, class(X));
%     myinf(1) = Inf;
%     avgDWithin = repmat(myinf, N, 1);
%     avgDBetween = repmat(myinf, N, K);
%     for j = 1:N
%         if strcmp(distMeasure, 'euclidean')
%             distj = sqrt(sum(bsxfun(@minus,X,X(j,:)).^2, 2));
%         elseif strcmp(distMeasure, 'sqeuclidean')
%             distj = sum(bsxfun(@minus,X,X(j,:)).^2, 2);
%         elseif strcmp(distMeasure, 'cityblock')
%             distj = sum(abs(bsxfun(@minus,X,X(j,:))), 2);
%         elseif strcmp(distMeasure, 'cosine') || strcmp(distMeasure, 'correlation')
%             distj = 1 - (X * X(j,:)');
%         elseif strcmp(distMeasure, 'hamming')
%             distj = sum(bsxfun(@ne,X,X(j,:)), 2) / D;
%         elseif strcmp(distMeasure, 'jaccard')
%             nzero = bsxfun(@or,(X~=0),(X(j,:)~=0));
%             nequal = bsxfun(@ne,X,X(j,:));
%             distj = sum(nequal & nzero, 2) ./ sum(nzero, 2);
%         else
%             error('unknown distMeasure');
%         end
% 
%         % Compute average distance by cluster number
%         for i = 1:K
%             if i == idx(j)
%                 avgDWithin(j) = sum(distj(mbrs(:,i))) ./ max(count(i)-1, 1);
%             else
%                 avgDBetween(j,i) = sum(distj(mbrs(:,i))) ./ count(i);
%             end
%         end
%     end
% 
%     % Calculate the silhouette values
%     minavgDBetween = min(avgDBetween, [], 2);
%     s = (minavgDBetween - avgDWithin) ./ max(avgDWithin,minavgDBetween);
% end
