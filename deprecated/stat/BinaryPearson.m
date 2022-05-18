% deprecated
function [retVal] = BinaryPearson (d, x, stdOfX)
    assert(islogical(d), 'd must be binary (boolean)');
    assert(islogical(x), 'x must be binary (boolean)');
    if ~exist('stdOfX', 'var') || isempty(stdOfX)
        stdOfX = std(x, 1); %TODO: should be numMIs x 1 - population standard devation for each of D columns in x
    end
%     numMIs = size(x, 2);
    N = size(d, 1); % length

    countD = sum(d);

    countX = sum(x, 1);
    countDX = sum(x(d,:), 1);

    stdVal = std(d); % calculate stddev for d (a scalar)
    cov = (N .* countDX - countD.*countX) ./ (N*N);
    retVal = cov ./ (stdVal .* stdOfX);
end