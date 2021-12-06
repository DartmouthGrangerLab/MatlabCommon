% Prediction of naive Bayes classifier with independent Gaussian.
% input:
%   model: trained model structure
%   X: d x n data matrix
% output:
%   y: 1 x n predicted class label
% Written by Mo Chen (sth4nth@gmail.com)
% downloaded by Eli Bowen 12/5/2021 from https://www.mathworks.com/matlabcentral/fileexchange/55864-naive-bayes-classifier
% edited only for argument validation, clarity, and style consistency
function [y] = nbGaussPred(model, X)
    validateattributes(model, 'struct', {'nonempty'});
    validateattributes(X,     {'numeric','logical'}, {'nonempty'});
    assert(all(size(model.mu) == size(model.var)));
    mu = model.mu;
    var = model.var;
    w = model.w;
    d = size(mu, 1);

    lambda = 1 ./ var;
    ml = mu .* lambda;
    M = bsxfun(@plus, lambda'*X.^2-2*ml'*X, dot(mu, ml, 1)'); % M distance
    c = d*log(2*pi) + 2*sum(log(var), 1)'; % normalization constant
    R = -0.5 * bsxfun(@plus, M, c);
    [~,y] = max(bsxfun(@times, exp(R), w), [], 1);
end