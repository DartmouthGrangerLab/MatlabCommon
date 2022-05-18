% deprecated
function [p] = CompareCorrCoeffs (r1, r2, n1, n2)
    t_r1 = 0.5 * log((1+r1)/(1-r1)); %this is "r'", the fisher transform of r1 (natural log is correct)
    t_r2 = 0.5 * log((1+r2)/(1-r2)); %this is "r'", the fisher transform of r2 (natural log is correct)
    z = (t_r1-t_r2) / sqrt(1/(n1-3)+1/(n2-3));
    p = (1 - normcdf(abs(z), 0, 1)) * 2;
end