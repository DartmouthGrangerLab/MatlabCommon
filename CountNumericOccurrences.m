% Eli Bowen
% 1/16/17
% NOTE: counts has the same number of elements (and same order), as unique(arr).
% omits nans
% INPUTS:
%   arr - 1D array (numeric, usually int-valued)
%   uniqueArr - OPTIONAL, default = unique(arr)
% RETURNS:
%   counts - number of entries for each unique number, same dimensionality as uniqueArr
function [counts] = CountNumericOccurrences (arr, uniqueArr)
    validateattributes(arr, {'numeric'}, {});
    if isempty(arr)
        if ~exist('uniqueArr', 'var') || isempty(uniqueArr)
            counts = [];
        else
            counts = zeros(size(uniqueArr), 'like', uniqueArr);
        end
        return;
    end
    isNan = isnan(arr);
    if any(isNan)
        arr(isNan) = []; % omit nans (for efficiency, don't change arr if not needed)
    end
    if exist('uniqueArr', 'var') && ~isempty(uniqueArr)
        validateattributes(uniqueArr, {'numeric'}, {'nonempty','vector','nonnan'});
        assert(numel(uniqueArr) == numel(unique(uniqueArr)) && issorted(uniqueArr, 'ascend'));
    else
        uniqueArr = unique(arr);
    end

    if numel(uniqueArr) == max(uniqueArr) && all(uniqueArr(:)' == 1:numel(uniqueArr))
        % below is suuuper fast, but to use it with uniqueArr ~= 1:nUniqueNums we need to run unique with nargout=3 which is slow
        counts = accumarray(arr(:), ones(numel(arr), 1), [numel(uniqueArr),1])';
    elseif numel(arr) * numel(uniqueArr) * 64 / 8 / 1024 / 1024 / 1024 < DetermineComputerRAMSize()
        counts = sum(arr(:)'==uniqueArr(:), 2)'; % implicit expansion, 2x as fast as loops (but briefly creates large matrices sometimes)
    else
        % this will be very slow whenever called
        counts = zeros(1, numel(uniqueArr));
        for i = 1:numel(uniqueArr)
            counts(i) = sum(arr==uniqueArr(i));
        end
    end
    % another way is below (2x speed of the slowest method, but it needs major debugging)
%     [~,idxa,idxc] = unique(arr);
%     [countsTemp,~,idxTemp] = histcounts(idxc, numel(idxa));

    if size(uniqueArr, 2) == 1
        counts = counts'; % output vector in same row/col orientation as input
    end
end