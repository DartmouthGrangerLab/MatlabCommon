% Calculates d' (aka the discriminability index aka the sensitivity index)
% This is related to the area under the curve for the ROC
% INPUT FOR 2-ALTERNATIVE FORCED-CHOICE TASKS (technically, this is an 'approximation'):
%   TP - number of true positives
%   P - number of positive responses given (predicted labels, not ground truth)
%   N - number of negative responses given (predicted labels, not ground truth)
% INPUT FOR MAGNITUDE SCORES WITH TWO LABELS:
%   signal - a bunch of samples of a scalar measure, considered to be samples from a non-noise distribution
%   noise - a bunch of samples of a scalar measure, considered to be samples from the noise distribution. need not be same size as signal - there is no 1:1 correspondence
% RETURNS:
%   dprime
%   beta - only returned if using the TP, P, N format
% Modified by Eli to add the second (signal,noise) formulation (https://en.wikipedia.org/wiki/Sensitivity_index)
function [dprime,beta] = DPrime (TP, P, N, signal, noise)
    if exist('TP', 'var') && ~isempty(TP) && exist('P', 'var') && ~isempty(P) && exist('N', 'var') && ~isempty(N)
        assert((~exist('signal', 'var') || isempty(signal)) && (~exist('noise', 'var') || isempty(noise)), 'must either pass TP, P, N -or- signal, noise');

        % z-score the results (this is part of the equation)
        zHitRate = norminv(TP/P);
        zFPRate = norminv((P-TP)/N);
        dprime = zHitRate - zFPRate;

        % -- If requested, calculate BETA
        if (nargout > 1)
            yHitRate = normpdf(zHitRate);
            yFPRate  = normpdf(zFPRate);
            beta = yHitRate ./ yFPRate;
        end
    elseif exist('signal', 'var') && ~isempty(signal) && exist('noise', 'var') && ~isempty(noise)
        assert((~exist('TP', 'var') || isempty(TP)) && (~exist('P', 'var') || isempty(P)) && (~exist('N', 'var') || isempty(N)), 'must either pass TP, P, N -or- signal, noise');

        dprime = (mean(signal) - mean(noise)) / sqrt(0.5 * (std(signal).^2 + std(noise).^2));
        beta = [];
    else
        error('must either pass TP, P, N -or- signal, noise');
    end
end