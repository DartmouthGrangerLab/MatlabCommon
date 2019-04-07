%Matlab's polynomial regression sucks at best. Here's a nicer version.
%Based on: http://www.mathworks.com/help/matlab/data_analysis/linear-regression.html#bswinlz
%INPUTS:
%   x - first variable
%   y - second variable
%   n - nth order polynomial (e.g. 3=cubic)
%RETURNS:
%   coeffs - the coefficients (betas) for the polynomial - coeffs(end) is the intercept of the predictor
%   yfit - predicted y values (e.g. for n=3, yfit = coeffs(1) * x.^3 + coeffs(2) * x.^2 + coeffs(3) * x + coeffs(4))
%   resid - residuals
%   rSquared - R^2
%   adjRSquared - adjusted R^2 (based on the fact that we're adding more degrees of freedom as we increase n)
function [coeffs,yfit,resid,rSquared,adjRSquared] = PolynomialRegression (x, y, n)
    validateattributes(x, {'numeric'}, {'vector'}, 'PolynomialRegression', 'x', 1);
    validateattributes(y, {'numeric'}, {'vector'}, 'PolynomialRegression', 'y', 2);
    validateattributes(n, {'numeric'}, {'scalar','integer','positive'}, 'PolynomialRegression', 'n', 3);
    assert(numel(x) == numel(y));
    x = x(:); %matlab doesn't like transposed vector orientation
    y = y(:); %matlab doesn't like transposed vector orientation
    
    %call polyfit to generate a cubic fit to predict y from x
    [coeffs,S] = polyfit(x, y, n); %coeffs(end) is the intercept

    %use the coefficients in p to predict y
    yfit = polyval(coeffs, x);
    
    %compute the residual values as a vector of signed numbers
    resid = y - yfit;

    %square the residuals and total them to obtain the residual sum of squares
    ssResid = sum(resid.^2);

    %compute the total sum of squares of y by multiplying the variance of y by # observations - 1
    ssTotal = (length(y)-1) * var(y);

    %compute simple R^2 for the cubic fit
    rSquared = 1 - ssResid/ssTotal;

    %finally, compute adjusted R^2 to account for degrees of freedom
    adjRSquared = 1 - ssResid/ssTotal * (length(y)-1)/(length(y)-length(coeffs));
end