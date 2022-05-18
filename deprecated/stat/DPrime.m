% deprecated
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