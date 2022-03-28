% Eli Bowen 11/27/17 ported from DoEqualizeStd()
% assumes we're happy with our mean, and just adjusts the standard deviations to be 1
% nice combination of low-memory-usage and high-performance
% INPUTS:
%   data - ? x ? (numeric)
% RETURNS:
%   data  - ? x ? (numeric)
%   sigma - 1 x ? (numeric) each standard deviation before we normalized it to equal 1
function [data,sigma] = EqualizeStd(data)
    sigma = zeros(1, size(data, 2));
    for i = 1:numel(sigma)
        sigma(i) = sum(data(:,i).^2, 1);
    end
    sigma = sqrt(sigma ./ (size(data, 1)-1));
%     means = sum(data, 1) ./ size(data, 1);
%     for i = 1:numel(sigma)
%         sigma(i) = sum((data(:,i) - means(i)).^2, 1);
%     end
%     sigma = sqrt(sigma ./ (size(data, 1)-1));
    
    sigma(sigma==0) = 1;
    data = bsxfun(@rdivide, data, sigma);
    
    error('needs a tad of work to be flexible about what dim youre equalizing');
end