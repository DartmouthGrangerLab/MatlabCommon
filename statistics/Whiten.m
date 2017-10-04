%Eli Bowen
%11/8/16
%Whitens the data. This is a simplified (and GPU-supported) version of the code from fastica.
%other versions of the code @ https://theclevermachine.wordpress.com/2013/03/30/the-statistical-whitening-transform/ https://xcorr.net/2011/05/27/whiten-a-matrix-matlab-code/ 
%INPUTS
%   data - #datapts x #dimensions MUST be mean-centered first
function [data,whiteningMat,dewhiteningMat] = Whiten (data)
    assert(isreal(data), 'input data must be real!');
    if any(abs(mean(zscore(data))) > eps()*size(data,1))
        error('data must be mean-centered first!'); %this is a soft sanity check - error is large, so within error of 0 is a loose check
    end
    
    %PCA
    covarianceMatrix = cov(data, 1);
    [E,D] = eig(covarianceMatrix);
    if any(any(D < 0))
        error('The covariance matrix cov(data, 1) is not positive-semidefinite! Make sure you mean-centered the input first, but that is only one of several potential problems.'); %https://www.quora.com/When-will-a-matrix-have-negative-eigenvalues-And-what-does-that-mean
    end
    
    %Whitening
    whiteningMat = inv(sqrt(D)) * E';
    dewhiteningMat = E * sqrt(D);
    data =  data * whiteningMat;
    
    assert(isreal(whiteningMat), 'Whitened vectors have imaginary values. Something is wrong with the input - perhaps you should mean center it?');
end