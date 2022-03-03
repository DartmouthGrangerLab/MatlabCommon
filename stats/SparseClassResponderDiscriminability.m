% Eli Bowen 3/2022
% INPUTS:
%   hist - n_classes x n_discriminators (numeric)
% RETURNS:
%   discriminability - 1 x n_discriminators (numeric)
%   sharedness       - 1 x n_discriminators (numeric) the fraction of classes that a discriminator is selective for
function [discriminability,sharedness] = SparseClassResponderDiscriminability(hist)
    validateattributes(hist, 'numeric', {'nonnegative'});
    [n_classes,n_discriminators] = size(hist);

    hist = hist ./ max(hist, [], 1); % must be ranged 0 --> 1 since the sigmoid ranges 0 --> 1

    % fit a logistic / sigmoid
%     func = @(b,x)(1 ./ (1 + exp(-b(1)*(x-b(2)))));
%     b0 = [1,n_classes/2]; % initial values fed into the iterative algorithm
%     for i = 1 : n_discriminators
%         bFit = nlinfit(1:n_classes, sort(hist(:,i)), func, b0);
%         % b(1) = curve steepness
%         % b(2) = midpoint x location
%         discriminability(i) = bFit(1);
%         sharedness(i) = n_classes - bFit(2);
%     end

    % a simpler way
    mask = (hist > 0.5);
    discriminability = zeros(1, n_discriminators);
    for i = 1 : n_discriminators
        discriminability(i) = mean(hist(mask(:,i),i)) - mean(hist(~mask(:,i),i));
    end
    sharedness = sum(mask, 1) ./ n_classes; % 1 x n_discriminators

    %TODO: deal with negative histograms
    %PROBLEM: what does it mean to be <0?
    %   also, if we leave things 0-->1, we can simply use the dilated image as a feature, because we'll be able to use ORs (an unused synapse won't count against us)
end