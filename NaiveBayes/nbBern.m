% Naive bayes classifier with indepenet Bernoulli
% Input:
%   X: d x n data matrix
%   t: 1 x n label (1~k)
% Output:
%   model: trained model structure
% Written by Mo Chen (sth4nth@gmail.com).
% downloaded by Eli Bowen 12/5/2021 from https://www.mathworks.com/matlabcentral/fileexchange/55864-naive-bayes-classifier
% edited only for argument validation, clarity, and style consistency
function [model] = nbBern(X, t)
    validateattributes(X, {'numeric','logical'}, {'nonempty'});
    validateattributes(t, 'numeric', {'nonempty','vector'});
    assert(size(X, 2) == numel(t));
    t = t(:)';

    k = max(t);
    n = size(X, 2);
    E = sparse(t, 1:n, 1, k, n, n);
    nk = full(sum(E, 2));
    w = nk / n;
    mu = full(sparse(X) * E' * spdiags(1./nk, 0, k, k));  

    model.mu = mu; % d x k means 
    model.w = w;
end