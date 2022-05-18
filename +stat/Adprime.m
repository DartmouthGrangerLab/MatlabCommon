% calculates Ad' (yes / no tasks)
% technically, this is an 'approximation'
% Ad' is the number of correct responses expected had this been a 2 alternative forced-choice task
% It can also be viewed as the area under the ROC curve
% see Stanislaw, H and Todorov, N "Calculation of signal detection theory measures” Behavior Research Methods, Instruments, & Computers 1999
% INPUTS
%   TP - number of true positives
%   P  - number of positive responses given (predicted labels, not ground truth)
%   N  - number of negative responses given (predicted labels, not ground truth)
function adprime = Adprime(TP, P, N)
    [dprime,~] = DPrime(TP, P, N);
    adprime = normcdf(dprime/sqrt(2)); %normcdf is also known as the "phi" function
    error('TODO: this should be right, but it hasn''t been validated!');
end