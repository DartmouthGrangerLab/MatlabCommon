% given an image and pooling range, returns a matrix of the image's maximum
% values in each neighborhood defined by the pooling range
% INPUTS:
%   img: a 2-dimensional matrix, the image to be filtered
%   poolSize: a scalar, P, such that each maximum will be taken over a P x P area of pixels
% RETURNS:
%   maxValues: a matrix whose size depends on poolSize, contains the maximum values found in poolSize x poolSize areas across img
% modified by eli for readability and performance
function [maxValues] = maxFilter (img, poolSize)
    halfpool = poolSize / 2;

    if isgpuarray(img) % imdilate seems to only support uint8 for gpuarrays
        maxValues = imdilate(uint8(255.*img), strel('square', poolSize));
        maxValues = double(maxValues(1:halfpool:end,1:halfpool:end)) ./ 255;
    else
        maxValues = imdilate(img, strel('square', poolSize));
        maxValues = maxValues(1:halfpool:end,1:halfpool:end);
    end
    % above is 5x faster, offset by a pixel or 2 from the original code (below), but actually more correct (compare with img)
%     [nRows,nCols] = size(img);
%     rowIdx = 1:halfpool:nRows;
%     colIdx = 1:halfpool:nCols;
%     maxValues = zeros(numel(rowIdx), numel(colIdx), 'like', img);
%     cCount = 1;
%     for c = colIdx
%         rCount = 1;
%         for r = rowIdx
%             maxValues(rCount,cCount) = max(max(img(r:min(r+poolSize-1,nRows),c:min(c+poolSize-1,nCols))));
%             rCount = rCount + 1;
%         end
%         cCount = cCount + 1;
%     end
end