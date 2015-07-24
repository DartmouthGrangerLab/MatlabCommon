%Technically, this is an 'approximation'
%Input:
%   TP - number of true positives
%   P - number of positive responses given (predicted labels, not ground truth)
%   N - number of negative responses given (predicted labels, not ground truth)
function [dprime,beta] = DPrime (TP, P, N)
    %z-score the results (this is part of the equation)
    zHitRate = norminv(TP/P);
    zFPRate = norminv((P-TP)/N);
    dprime = zHitRate - zFPRate;
    
    %-- If requested, calculate BETA
    if (nargout > 1)
        yHitRate = normpdf(zHitRate);
        yFPRate  = normpdf(zFPRate);
        beta = yHitRate ./ yFPRate;
    end
end