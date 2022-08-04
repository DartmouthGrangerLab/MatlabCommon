% deprecated (instead, see ml package)
function [idx,centroids,L,U] = SpectralClustering(W, k, type, init, n_iter)
    validateattributes(W,    {'numeric'}, {}, 1);
    validateattributes(k,    {'numeric'}, {'nonempty','scalar','positive','integer'}, 2);
    validateattributes(type, {'numeric'}, {'nonempty','scalar','positive','integer'}, 3);
    if ~exist('init', 'var') || isempty(init)
        init = 'sample'; % value from the original code
    end
    if ~exist('n_iter', 'var') || isempty(n_iter)
        n_iter = 100; % value from the original code (also the matlab default)
    end
    if strcmp(init, 'random')
        init = 'sample';
    end
    if strcmp(init, 'kmeans++')
        init = 'plus';
    end

    %% calculate degree matrix
    degs = sum(W, 2);
    D    = sparse(1:size(W, 1), 1:size(W, 2), degs);

    %% compute unnormalized Laplacian
    L = D - W;

    %% compute normalized Laplacian if needed
    switch type
        case 2
            degs(degs == 0) = eps; % avoid dividing by zero
            D = spdiags(1./degs, 0, size(D, 1), size(D, 2)); % calculate inverse of D
            L = D * L; % calculate normalized Laplacian
        case 3
            degs(degs == 0) = eps; % avoid dividing by zero
            D = spdiags(1./(degs.^0.5), 0, size(D, 1), size(D, 2)); % calculate D^(-1/2)
            L = D * L * D; % calculate normalized Laplacian
    end

    %% compute the eigenvectors corresponding to the k smallest eigenvalues
    diff = eps;
    [U,~] = eigs(L, k, diff); % each column of U is an eigenvector

    % in case of the Jordan-Weiss algorithm, we need to normalize the eigenvectors row-wise
    if type == 3
        U = bsxfun(@rdivide, U, sqrt(sum(U.^2, 2)));
    end

    %% now use the k-means algorithm to cluster U row-wise
    % idx will be a n-by-1 matrix containing the cluster number for each data point
    [idx,centroids] = kmeans(U, k, 'start', init, 'EmptyAction', 'singleton', 'MaxIter', n_iter);
end