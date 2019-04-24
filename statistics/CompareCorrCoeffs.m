% This function compare if two correlation coefficients are significantly different.
% The correlation coefficients were tansfered to z scores using fisher's r to z transformation. 
% ref: http://core.ecu.edu/psyc/wuenschk/docs30/CompareCorrCoeff.pdf
%--------------------------------------------------------------------------
% INPUTS:
%   (1) r1: correlation coefficient of the first correlation
%   (2) r2: correlation coefficient of the second correlation
%   (3) n1: number of samples used to compute the first correlation
%   (4) n2: number of samples used to compute the second correlation
%--------------------------------------------------------------------------
% Output:
%   (1) p: p value, the probability that H0 (the correlation coefficiets are not different) is correct
%--------------------------------------------------------------------------
% Example :
% x = rand(20,1); 
% y1= x+rand(20,1)*0.05;
% y2= x+rand(20,1)*0.5;
% r1=corr(x,y1);
% r1=corr(x,y2);
% p = compare_correlation_coefficients(r1,r2,length(x),length(x));
%--------------------------------------------------------------------------
%Downloaded by Eli Bowen 4/11/2019 from https://www.mathworks.com/matlabcentral/fileexchange/44658-compare_correlation_coefficients
%Modified only for readability
%according to wikipedia (citing "Spearman Rank Correlation: Overview. Encyclopedia of Biostatistics"), this is valid for spearman corr as well as pearson
%see also:
%   https://en.wikipedia.org/wiki/Fisher_transformation
%   http://vassarstats.net/rdiff.html
%   https://stats.stackexchange.com/questions/99741/how-to-compare-the-strength-of-two-pearson-correlations
function [p] = CompareCorrCoeffs (r1, r2, n1, n2)
    t_r1 = 0.5 * log((1+r1)/(1-r1)); %natural log is correct
    t_r2 = 0.5 * log((1+r2)/(1-r2));
    z = (t_r1-t_r2) / sqrt(1/(n1-3)+1/(n2-3));
    p = (1 - normcdf(abs(z), 0, 1)) * 2;
end