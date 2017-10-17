%Eli Bowen
%10/16/17
%copied from InfoTheory.java, adapted from the Java Mutual Information Toolbox (JavaMI)
%INPUTS:
%   d - N-dimensional vector (binary)
%   x - N x numMIs (binary)
function [retVal] = BinaryPearson (d, x)
    assert(islogical(d), 'd must be binary (boolean)');
    assert(islogical(x), 'x must be binary (boolean)');
%     numMIs = size(x, 2);
    N = size(d, 1); %Length
    
    stdOfX = std(x, 1); %TODO: should be numMIs x 1 - population standard devation for each of D columns in x
    countD = sum(d);
    
    countX = sum(x, 1);
    countDX = sum(x(d==1,:), 1);
    
    stdVal = std(d); %calculate stddev for d (a scalar)
    cov = (N .* countDX - countD.*countX) ./ (N*N);
    retVal = cov ./ (stdVal .* stdOfX);
end