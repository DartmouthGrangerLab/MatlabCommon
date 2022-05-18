% deprecated
function [adprime] = Adprime (TP, P, N)
    error('TODO: this should be right, but it hasn''t been validated!');
    [dprime,~] = DPrime(TP, P, N);
    adprime = normcdf(dprime/sqrt(2)); %normcdf is also known as the "phi" function
end