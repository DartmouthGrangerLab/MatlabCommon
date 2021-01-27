%Eli Bowen
%1/16/17
%NOTE: counts has the same number of elements (and same order), as unique(arr).
%omits nans
%INPUTS:
%   arr - 1D array of numbers (probably integers?)
%   uniqueNumbers - OPTIONAL, default = unique(arr)
%RETURNS:
%   counts - number of entries for each unique number, same dimensionality as uniqueNumbers
function [counts] = CountNumericOccurrences (arr, uniqueNumbers)
    validateattributes(arr, {'numeric'}, {'nonempty','vector'});
    if isempty(arr)
        counts = [];
        return;
    end
    isNan = isnan(arr);
    if any(isNan)
        arr(isNan) = []; % omit nans (for efficiency, don't change arr if not needed)
    end
    if exist('uniqueNumbers', 'var') && ~isempty(uniqueNumbers)
        validateattributes(uniqueNumbers, {'numeric'}, {'nonempty','vector','nonnan'});
        assert(numel(uniqueNumbers) == numel(unique(uniqueNumbers)) && issorted(uniqueNumbers, 'ascend'));
    else
        uniqueNumbers = unique(arr);
    end

    if numel(uniqueNumbers) == max(uniqueNumbers) && all(uniqueNumbers(:)' == 1:numel(uniqueNumbers))
        % below is suuuper fast, but to use it with uniqueNumbers ~= 1:nUniqueNums we need to run unique with nargout=3 which is slow
        counts = accumarray(arr(:), ones(numel(arr), 1), [numel(uniqueNumbers),1])';
    elseif numel(arr) * numel(uniqueNumbers) * 64 / 8 / 1024 / 1024 / 1024 < DetermineComputerRAMSize()
        counts = sum(arr(:)'==uniqueNumbers(:), 2)'; % implicit expansion, 2x as fast as below (but briefly creates large matrices sometimes)
    else
        % this will be very slow whenever called
        counts = zeros(1, numel(uniqueNumbers));
        for i = 1:numel(uniqueNumbers)
            counts(i) = sum(arr==uniqueNumbers(i));
        end
    end
    % another way is below (2x speed of the slowest method, but it needs major debugging)
%     [~,idxa,idxc] = unique(arr);
%     [countsTemp,~,idxTemp] = histcounts(idxc, numel(idxa));

    if size(uniqueNumbers, 2) == 1
        counts = counts'; % output vector in same row/col orientation as input
    end
end