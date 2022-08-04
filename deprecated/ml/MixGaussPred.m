% deprecated (instead, see ml package)
function [label,R] = MixGaussPred(X, model)
    assert(size(X, 1) == size(model.mu, 1));

    mu = model.mu;
    sigma = model.sigma;
    w = model.w;
    N = size(X, 2);
    K = size(mu, 2);
    logRho = zeros(N, K);
    for i = 1 : K
        logRho(:,i) = loggausspdf(X, mu(:,i), sigma(:,:,i));
    end
    logRho = bsxfun(@plus, logRho, log(w));
    T = logsumexp(logRho, 2);
    logR = bsxfun(@minus, logRho, T);
    R = exp(logR);
    [~,label(1,:)] = max(R, [], 2);
end