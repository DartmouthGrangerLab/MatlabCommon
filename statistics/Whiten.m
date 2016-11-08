%Eli Bowen
%11/8/16
%Whitens the data. This is a simplified (and GPU-supported) version of the code from fastica.
%INPUTS
%   data - #datapts x #dimensions MUST be mean-centered first
function [whiteData,whiteningMat,dewhiteningMat] = Whiten (data)
    if any(abs(mean(zscore(data))) > eps()*size(data,1))
        error('data must be mean-centered first!'); %this is a soft sanity check
    end
    
    %PCA
    covarianceMatrix = cov(data, 1);
    [E,D] = eig(covarianceMatrix);
    %Whitening
    whiteningMat = inv(sqrt(D)) * E';
    dewhiteningMat = E * sqrt(D);
    whiteData =  data * whiteningMat;
    
    if ~isreal(whiteData) %safety check
        error('Whitened vectors have imaginary values. Something is wrong with the input - perhaps you should mean center it?');
    end
end