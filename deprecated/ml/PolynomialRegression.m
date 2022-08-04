% deprecated (instead, see ml package)
function [model,yfit,resid,rSquared,adjRSquared] = PolynomialRegression(x, y, n)
    validateattributes(x, {'numeric'}, {'vector'},                      'PolynomialRegression', 'x', 1);
    validateattributes(y, {'numeric'}, {'vector'},                      'PolynomialRegression', 'y', 2);
    validateattributes(n, {'numeric'}, {'scalar','integer','positive'}, 'PolynomialRegression', 'n', 3);
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