% based on: http://www.mathworks.com/help/matlab/data_analysis/linear-regression.html#bswinlz
% INPUTS
%   y        - n_pts x 1 (numeric) dv
%   yfit     - n_pts x 1 (numeric) regression predictions for the dv
%   n_coeffs - OPTIONAL scalar (int-valued numeric) number of coefficients / betas in the model
% RETURNS
%   resid       - residuals
%   rSquared    - scalar (numeric) R^2
%   adjRSquared - scalar (numeric) adjusted R^2 (based on the fact that we're adding more degrees of freedom as we increase n)
function [resid,rSquared,adjRSquared] = RegressionStats(y, yfit, n_coeffs)
    validateattributes(y,    {'numeric'}, {'vector'}, 1);
    validateattributes(yfit, {'numeric'}, {'vector'}, 2);
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

    % compute adjusted R^2 to account for degrees of freedom
    if nargout() > 2
        validateattributes(n_coeffs, 'numeric', {'nonempty','scalar','integer'});
        adjRSquared = 1 - ssResid/ssTotal * (numel(y)-1)/(numel(y)-n_coeffs);
    end
end