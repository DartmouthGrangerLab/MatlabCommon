%Eli Bowen
%10/16/17
%copied from InfoTheory.java, adapted from the Java Mutual Information Toolbox (JavaMI)
%INPUTS:
%   d - N-dimensional vector (binary)
%   x - N x numMIs (real valued)
%   stdOfX - OPTIONAL - precomputed value of exactly std(x, 1) - only useful for speeding up multiple calls with the same X
function [retVal] = PointBiserial (d, x, stdOfX)
    assert(islogical(d), 'd must be binary (boolean)');
    N = size(d, 1);
    
    if ~exist('stdOfX', 'var') || isempty(stdOfX)
        stdOfX = std(x, 1); %numMIs x 1 - population standard devation for each of D columns in x
    end

    n0 = sum(~d);
    n1 = sum(d);
    assert(n0~=0 && n1~=0, 'There is only one group!');
%     xMeans = zeros(2, numMIs); %Mean of groups 0 and 1
%     for i = 1:N
%         xMeans(d(i)+1,:) = xMeans(d(i)+1,:) + x(i,:);
%     end
%     xMeans(1,:) = xMeans(1,:) ./ n0;
%     xMeans(2,:) = xMeans(2,:) ./ n1;
    xMeans0 = mean(x(~d,:), 1);
    xMeans1 = mean(x(d,:), 1);
    
    c = sqrt(n0*n1/(N*N)); %scalar
    retVal = (xMeans1-xMeans0) ./ stdOfX * c; %Correlation coefficient
end
