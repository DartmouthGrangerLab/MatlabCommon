% Eli Bowen 10/14/2021
% https://en.wikipedia.org/wiki/Sensitivity_and_specificity
% INPUTS:
%   pred - 1 x n_datapts (logical)
%   target - 1 x n_datapts (logical)
% RETURNS:
%   sensitivity - scalar (numeric) - sensitivity aka true positive rate aka recall aka hitrate
%       false negative rate = 1 - sensitivity
%   specificity - scalar (numeric) - specificity aka true negative rate aka selectivity
%       false positive rate = 1 - specificity
%   precision - scalar (numeric) - precision aka positive predictive value
%       false discovery rate = 1 - precision
%   acc - scalar (numeric) - accuracy aka fraction correct
%   accBalanced - scalar (numeric) - accuracy, adjusted for unequal N
%   n_tp - scalar (int-valued numeric) - number of true positives
%   n_tn - scalar (int-valued numeric) - number of true negatives
%   n_fp - scalar (int-valued numeric) - number of false positives
%   n_fn - scalar (int-valued numeric) - number of false negatives
function [sensitivity,specificity,precision,acc,accBalanced,n_tp,n_tn,n_fp,n_fn] = SensitivitySpecificity(pred, target)
    validateattributes(pred,   {'logical'}, {'nonempty','vector','numel',numel(target)}, 1);
    validateattributes(target, {'logical'}, {'nonempty','vector','numel',numel(pred)}, 2);

    pred = pred(:)'; % make sure they're the same dimensionality
    target = target(:)';

    n_tp = sum(pred & target);
    n_tn = sum(~pred & ~target);
    n_fp = sum(pred & ~target);
    n_fn = sum(~pred & target);
%     n_p = sum(target);
%     n_n = sum(~target);

    sensitivity = n_tp / (n_tp + n_fn); % aka n_tp / n_p
    specificity = n_tn / (n_tn + n_fp); % aka n_tn / n_n
    precision   = n_tp / (n_tp + n_fp);
    acc = sum(pred == target) / numel(target); % aka (n_tp + n_tn) / (n_p + n_n)
    accBalanced = (sensitivity + specificity) / 2; % aka ((n_tp / n_p) + (n_tn / n_n)) / 2;
end