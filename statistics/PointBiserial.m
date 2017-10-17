%Eli Bowen
%10/16/17
%copied from InfoTheory.java, adapted from the Java Mutual Information Toolbox (JavaMI)
%INPUTS:
%   d - N-dimensional vector (binary)
%   x - N x numMIs (real valued)
function [retVal] = PointBiserial (d, x)
    assert(islogical(d), 'd must be binary (boolean)');
%     numMIs = size(x, 2);
    N = size(d, 1); %Length
%     xMeans = zeros(2, numMIs); %Mean of groups 0 and 1
    
    stdOfX = std(x, 1); %numMIs x 1 - population standard devation for each of D columns in x

    n0 = sum(d==0);
    n1 = sum(d==1);
    assert(n0~=0 && n1~=0, 'There is only one group!');
%     for i = 1:N
%         xMeans(d(i)+1,:) = xMeans(d(i)+1,:) + x(i,:);
%     end
%     xMeans(1,:) = xMeans(1,:) ./ n0;
%     xMeans(2,:) = xMeans(2,:) ./ n1;
    xMeans(1,:) = mean(x(d==0,:), 1);
    xMeans(2,:) = mean(x(d==1,:), 1);
    
    c = sqrt(n0*n1/(N*N)); %scalar
    retVal = (xMeans(2,:)-xMeans(1,:)) ./ stdOfX * c; %Correlation coefficient
end