% naive bayes classifier with indepenet Bernoulli
% INPUTS:
%   X:        d x n (numeric or logical) data matrix
%   labelIdx: 1 x n (int-valued numeric) label (1~k)
% RETURNS:
%   model: trained model structure
% Written by Mo Chen (sth4nth@gmail.com)
% downloaded by Eli Bowen 12/5/2021 from https://www.mathworks.com/matlabcentral/fileexchange/55864-naive-bayes-classifier
% edited only for argument validation, clarity, and style consistency
function [model] = nbBern(X, labelIdx)
    validateattributes(X,        {'numeric','logical'}, {'nonempty'});
    validateattributes(labelIdx, 'numeric',             {'nonempty','vector'});
    assert(size(X, 2) == numel(labelIdx));
    labelIdx = labelIdx(:)';

    n = size(X, 2);
    k = max(labelIdx); % n_classes

    E = full(sparse(labelIdx, 1:n, 1, k, n, n)); % create a 1-hot label code (n x k)
    nk = sum(E, 2);         % k x 1 (int-valued numeric) num datapoints per class
    w = nk ./ n;            % k x 1 (numeric)
    dia = diag(1 ./ nk, 0); % k x k (numeric) diagonal matrix (with values of 1./nk along the diagonal)
    mu = X * (E' * dia);
    % above seems 10x faster than below
%     E = sparse(labelIdx, 1:n, 1, k, n, n); % create a 1-hot label code
%     nk = full(sum(E, 2));          % k x 1 (int-valued numeric)
%     w = nk ./ n;                   % k x 1 (numeric)
%     dia = spdiags(1./nk, 0, k, k); % k x k (int-valued numeric) diagonal matrix (with values of 1./nk along the diagonal)
%     R = E' * dia;                  % n x k
%     mu = full(sparse(X) * R);

    model = struct();
    model.name = 'nb';
    model.dist = 'bern';
    model.w = w;   % k x 1
    model.mu = mu; % d x k means
end