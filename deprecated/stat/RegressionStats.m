% deprecated
function [resid,rSquared,adjRSquared] = RegressionStats(y, yfit, n_coeffs)
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

    % compute adjusted R^2 to account for degrees of freedom
    if nargout() > 2
        validateattributes(n_coeffs, 'numeric', {'nonempty','scalar','integer'});
        adjRSquared = 1 - ssResid/ssTotal * (numel(y)-1)/(numel(y)-n_coeffs);
    end
end