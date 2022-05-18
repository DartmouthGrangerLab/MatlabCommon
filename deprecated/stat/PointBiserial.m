% deprecated
function [ret] = PointBiserial(d, x, stdOfX)
    validateattributes(d, {'logical'}, {'vector'}, 1);
    N = numel(d, 1);

    if ~exist('stdOfX', 'var') || isempty(stdOfX)
        stdOfX = std(x, 1); % n_predictors x 1 - population standard devation for each of D columns in x
    end

    n0 = sum(~d);
    n1 = sum(d);
    assert(n0 ~= 0 && n1 ~= 0, 'there is only one group!');
%     xMeans = zeros(2, n_predictors); % mean of groups 0 and 1
%     for i = 1 : N
%         xMeans(d(i)+1,:) = xMeans(d(i)+1,:) + x(i,:);
%     end
%     xMeans(1,:) = xMeans(1,:) ./ n0;
%     xMeans(2,:) = xMeans(2,:) ./ n1;
    xMeans0 = mean(x(~d,:), 1);
    xMeans1 = mean(x(d,:), 1);

    c = sqrt(n0*n1/(N*N)); % scalar
    ret = (xMeans1-xMeans0) ./ stdOfX * c; % correlation coefficient
end