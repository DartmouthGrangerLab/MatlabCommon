% Prediction of naive Bayes classifier with independent Gaussian.
% INPUTS:
%   model: trained model structure
%   X:     d x n (numeric or logical) - data matrix
% RETURNS:
%   y: 1 x n (int-valued numeric) - predicted class label
% Written by Mo Chen (sth4nth@gmail.com)
% downloaded by Eli Bowen 12/5/2021 from https://www.mathworks.com/matlabcentral/fileexchange/55864-naive-bayes-classifier
% edited only for argument validation, clarity, and style consistency, then I merged nbGaussPred and nbBernPred.
function [y] = nbPred(model, X)
    validateattributes(model, 'struct', {'nonempty'});
    validateattributes(X,     {'numeric','logical'}, {'nonempty'});
    w = model.w;
    mu = model.mu;
    d = size(mu, 1);

    if strcmp(model.dist, 'gauss')
        var = model.var;

        lambda = 1 ./ var;
        ml = mu .* lambda;
        M = bsxfun(@plus, lambda'*X.^2-2*ml'*X, dot(mu, ml, 1)'); % M distance
        c = d*log(2*pi) + 2*sum(log(var), 1)'; % normalization constant
        R = -0.5 .* bsxfun(@plus, M, c);
%         R = exp(R) .* w; % original (R is often too large of a negative number to call exp on)
        R = R + log(w); % should equal log(original), the max of which should be the same index
    elseif strcmp(model.dist, 'bern')
        X = sparse(X);
        R = log(mu+eps)'*X + log(1-mu+eps)'*(1-X); % need eps: log(0) = -Inf, which dominates all other parts of the multiplication
        R = R + log(w);
    elseif strcmp(model.dist, 'multinomial')
        R = mu'*X + w; % calculate the posterior log probability of the samples X
        error('untested performance!');
    else
        error('unexpected model')
    end

    [~,y] = max(R, [], 1);
end