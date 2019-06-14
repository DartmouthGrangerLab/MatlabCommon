%Eli Bowen
%6/11/2019
%Fisher transform of correlation values to normal distribution, extracted from CompareCorrCoeffs.m (in MatlabCommon)
%applies both to Pearson and Spearman (https://en.wikipedia.org/wiki/Spearman's_rank_correlation_coefficient) correlation
%documentation: https://en.wikipedia.org/wiki/Fisher_transformation
%should be equivalent to "z = atanh(r)", and it appears to be
function [z] = FisherTransformCorr (r)
    z = 0.5 .* log((1+r) ./ (1-r)); %natural log is correct
end
