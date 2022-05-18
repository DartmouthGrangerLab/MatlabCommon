% Eli Bowen 6/11/2019
% inverse Fisher transform z to corr (see FisherTransformCorr.m)
% applies both to Pearson and Spearman (https://en.wikipedia.org/wiki/Spearman's_rank_correlation_coefficient) correlation
% documentation: https://en.wikipedia.org/wiki/Fisher_transformation
function r = FisherTransformCorrInverse(z)
    r = (exp(2.*z) - 1) ./ (exp(2.*z) + 1); % natural exponent is correct, exp(x) = e^x
end
