% deprecated
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