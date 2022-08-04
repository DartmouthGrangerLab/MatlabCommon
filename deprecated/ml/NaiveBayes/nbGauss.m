% deprecated (instead, see ml package)
function model = nbGauss(X, labelIdx)
    validateattributes(X,        {'numeric'}, {'nonempty'}, 1);
    validateattributes(labelIdx, {'numeric'}, {'nonempty','vector'}, 2);
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
    model.name = 'nb';
    model.dist = 'gauss';
    model.w = w;     % k x 1
    model.mu = mu;   % d x k means 
    model.var = var; % d x k variances

    assert(all(size(model.mu) == size(model.var)));
end