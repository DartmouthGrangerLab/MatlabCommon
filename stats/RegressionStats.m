% based on: http://www.mathworks.com/help/matlab/data_analysis/linear-regression.html#bswinlz
% INPUTS:
%   y    - 1 x n_pts (numeric) dv
%   yfit - 1 x n_pts (numeric) regression predictions for the dv
% RETURNS:
%   resid       - residuals
%   rSquared    - scalar (numeric) R^2
%   adjRSquared - scalar (numeric) adjusted R^2 (based on the fact that we're adding more degrees of freedom as we increase n)
function [resid,rSquared,adjRSquared] = RegressionStats(y, yfit)
    validateattributes(y,    'numeric', {'vector'});
    validateattributes(yfit, 'numeric', {'vector'});
    y = y(:);
    yfit = yfit(:);

    % compute the residual values as a vector of signed numbers
    resid = y - yfit;

    % square the residuals and total them to obtain the residual sum of squares
    ssResid = sum(resid .^ 2); % scalar

    % compute the total sum of squares of y by multiplying the variance of y by # observations - 1
    ssTotal = (numel(y)-1) * var(y); % scalar

    % compute simple R^2 for the cubic fit
    rSquared = 1 - ssResid/ssTotal;

    % finally, compute adjusted R^2 to account for degrees of freedom
    adjRSquared = 1 - ssResid/ssTotal * (numel(y)-1)/(numel(y)-numel(coeffs));
end