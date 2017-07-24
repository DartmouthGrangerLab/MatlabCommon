%Executes spectral clustering algorithm
%   Executes the spectral clustering algorithm defined by
%   Type on the adjacency matrix W and returns the k cluster indicator vectors as columns in C.
%   If L and U are also called, the (normalized) Laplacian and eigenvectors will also be returned.
% INPUTS:
%   'W' - Adjacency matrix, needs to be square
%   'k' - Number of clusters to look for
%   'Type' - Defines the type of spectral clustering algorithm that should be used. Choices are:
%      1 - Unnormalized
%      2 - Normalized according to Shi and Malik (2000)
%      3 - Normalized according to Jordan and Weiss (2002)
%
%   References:
%   - Ulrike von Luxburg, "A Tutorial on Spectral Clustering", Statistics and Computing 17 (4), 2007
% borrowed from:
%   Author: Ingo Buerk
%   Year  : 2011/2012
%   Bachelor Thesis
function [idx,centroids,L,U] = SpectralClustering (W, k, Type)
    %% calculate degree matrix
    degs = sum(W, 2);
    D    = sparse(1:size(W, 1), 1:size(W, 2), degs);

    %% compute unnormalized Laplacian
    L = D - W;

    %% compute normalized Laplacian if needed
    switch Type
        case 2
            degs(degs == 0) = eps; %avoid dividing by zero
            D = spdiags(1./degs, 0, size(D, 1), size(D, 2)); %calculate inverse of D
            L = D * L; %calculate normalized Laplacian
        case 3
            degs(degs == 0) = eps; %avoid dividing by zero
            D = spdiags(1./(degs.^0.5), 0, size(D, 1), size(D, 2)); %calculate D^(-1/2)
            L = D * L * D; %calculate normalized Laplacian
    end

    %% compute the eigenvectors corresponding to the k smallest eigenvalues
    diff = eps;
    [U,~] = eigs(L, k, diff); %each column of U is an eigenvector

    % in case of the Jordan-Weiss algorithm, we need to normalize the eigenvectors row-wise
    if Type == 3
        U = bsxfun(@rdivide, U, sqrt(sum(U.^2, 2)));
    end

    %% now use the k-means algorithm to cluster U row-wise
    % C will be a n-by-1 matrix containing the cluster number for each data point
    [idx,centroids] = kmeans(U, k, 'start', 'sample', 'EmptyAction', 'singleton');
end