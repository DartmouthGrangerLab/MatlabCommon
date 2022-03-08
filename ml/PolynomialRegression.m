% matlab's polynomial regression sucks at best - here's a nicer version
% based on: http://www.mathworks.com/help/matlab/data_analysis/linear-regression.html#bswinlz
% USAGE:
%   [model,yfit,resid,rSquared,adjRSquared] = PolynomialRegression(x, y, n)
%   newYFit = polyval(model.coeffs, newX);
%   [resid,rSquared,adjRSquared] = RegressionStats(newY, newYFit);
% INPUTS:
%   x - 1 x n_pts (numeric) yes, must be a single predictor variable
%   y - 1 x n_pts (numeric) dv
%   n - scalar (int-valued numeric) nth order polynomial (e.g. 3 = cubic)
% RETURNS:
%   model       - the coefficients (betas) for the polynomial - coeffs(end) is the intercept of the predictor
%   yfit        - predicted y values (e.g. for n=3, yfit = coeffs(1) * x.^3 + coeffs(2) * x.^2 + coeffs(3) * x + coeffs(4))
%   resid       - residuals
%   rSquared    - scalar (numeric) R^2
%   adjRSquared - scalar (numeric) adjusted R^2 (based on the fact that we're adding more degrees of freedom as we increase n)
function [model,yfit,resid,rSquared,adjRSquared] = PolynomialRegression(x, y, n)
    validateattributes(x, 'numeric', {'vector'},                      'PolynomialRegression', 'x', 1);
    validateattributes(y, 'numeric', {'vector'},                      'PolynomialRegression', 'y', 2);
    validateattributes(n, 'numeric', {'scalar','integer','positive'}, 'PolynomialRegression', 'n', 3);
    assert(numel(x) == numel(y));
    x = x(:); % matlab doesn't like transposed vector orientation
    y = y(:); % matlab doesn't like transposed vector orientation

    model = struct();
    model.name = 'polynomial';
    model.coeffs = polyfit(x, y, n); % coeffs(end) is the intercept

    % make predictions on training set
    if nargout() > 1
        yfit = polyval(model.coeffs, x);

        [resid,rSquared,adjRSquared] = RegressionStats(y, yfit, numel(model.coeffs));
    end
end