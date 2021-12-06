% Prediction of naive Bayes classifier with independent Bernoulli.
% input:
%   model: trained model structure
%   X: d x n data matrix
% output:
%   y: 1 x n predicted class label
% Written by Mo Chen (sth4nth@gmail.com)
% downloaded by Eli Bowen 12/5/2021 from https://www.mathworks.com/matlabcentral/fileexchange/55864-naive-bayes-classifier
% edited only for argument validation, clarity, and style consistency
function [y] = nbBernPred(model, X)
    validateattributes(model, 'struct', {'nonempty'});
    validateattributes(X, {'numeric','logical'}, {'nonempty'});

    mu = model.mu;
    w = model.w;

    X = sparse(X);
    R = log(mu)'*X + log(1-mu)'*(1-X);
    R = bsxfun(@plus, R, log(w));
    [~,y] = max(R, [], 1);
end