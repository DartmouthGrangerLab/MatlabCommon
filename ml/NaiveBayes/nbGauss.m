% Naive bayes classifier with indepenet Gaussian, each dimension of data is assumed from a 1d Gaussian distribution with independent mean and variance
% INPUTS:
%   X:        d x n (numeric) data matrix
%   labelIdx: 1 x n (int-valued numeric) label (1~k)
% RETURNS:
%   model: trained model structure
% Written by Mo Chen (sth4nth@gmail.com)
% downloaded by Eli Bowen 12/5/2021 from https://www.mathworks.com/matlabcentral/fileexchange/55864-naive-bayes-classifier
% edited only for argument validation, clarity, and style consistency
function [model] = nbGauss(X, labelIdx)
    validateattributes(X,        'numeric', {'nonempty'});
    validateattributes(labelIdx, 'numeric', {'nonempty','vector'});
    assert(size(X, 2) == numel(labelIdx));
    if ~isa(X, 'double')
        X = double(X); % required for multiplying by a sparse matrix
    end
    labelIdx = labelIdx(:)';

    n = size(X, 2);
    k = max(labelIdx); % n_classes

    E = sparse(labelIdx, 1:n, 1, k, n, n); % create a 1-hot label code (n x k)
    nk = full(sum(E, 2));            % k x 1 (int-valued numeric) num datapoints per class
    w = nk ./ n;                     % k x 1 (numeric)
    dia = spdiags(1 ./ nk, 0, k, k); % k x k (numeric) diagonal matrix (with values of 1./nk along the diagonal)
    R = E' * dia; % n x k
    mu = X * R;
    var = X.^2 * R - mu.^2;

    model = struct();
    model.dist = 'gauss';
    model.w = w;     % k x 1
    model.mu = mu;   % d x k means 
    model.var = var; % d x k variances

    assert(all(size(model.mu) == size(model.var)));
end