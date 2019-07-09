%Eli Bowen
%1/16/17
%NOTE: counts has the same number of elements (and same order), as unique(arr).
%INPUTS:
%   arr - 1D array of numbers (probably integers?)
%   uniqueNumbers - OPTIONAL
function [counts] = CountNumericOccurrences (arr, uniqueNumbers)
    if ~exist('uniqueNumbers', 'var') || isempty(uniqueNumbers)
        uniqueNumbers = unique(arr);
    end
%     counts = zeros(numel(uniqueNumbers), 1);
%     for i = 1:numel(uniqueNumbers)
%         counts(i) = sum(arr==uniqueNumbers(i));
%     end
    counts = sum(arr(:)'==uniqueNumbers(:), 2); %implicit expansion, 2x as fast as above (but briefly creates large matrices sometimes)
end