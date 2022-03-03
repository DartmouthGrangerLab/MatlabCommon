% executes the spectral clustering algorithm on the adjacency matrix W and returns the k cluster indicator vectors as columns in C
% INPUTS:
%   W    - adjacency matrix, needs to be square
%   k    - number of clusters to look for
%   type - Defines the type of spectral clustering algorithm that should be used. Choices are:
%       1 - unnormalized
%       2 - normalized according to Shi and Malik (2000)
%       3 - normalized according to Jordan and Weiss (2002)
% RETURNS:
%   idx
%   centroids - k x p (numeric)
%   L         - normalized Laplacian
%   U         - eigenvectors
% REFERENCES:
%   Ulrike von Luxburg, "A Tutorial on Spectral Clustering", Statistics and Computing 17 (4), 2007
% borrowed from: Ingo Buerk 2011/2012, bachelor thesis
% modified by Eli Bowen just for clarity
function [idx,centroids,L,U] = SpectralClustering(W, k, type)
    validateattributes(W,    'numeric', {});
    validateattributes(k,    'numeric', {'nonempty','scalar','positive','integer'});
    validateattributes(type, 'numeric', {'nonempty','scalar','positive','integer'});

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
    % C will be a n-by-1 matrix containing the cluster number for each data point
    [idx,centroids] = kmeans(U, k, 'start', 'sample', 'EmptyAction', 'singleton');
end