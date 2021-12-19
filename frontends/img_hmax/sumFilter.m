% Given an image and pooling range, returns an image where each "pixel"
% represents the sums of the pixel values within the pooling range of the original pixel
% INPUTS:
%   imgIn: a 2-dimensional matrix, the image to be filtered
%   radius: a scalar or vector, the additional radius of the filter pool,
%       For a scalar, ex. radius = 5 means a filter pool of 11 x 11
%       For a vector, use the order [left top right bottom].
% RETURNS:
%   img: a matrix the size of input img, where each pixel, img(x,y),
%       represents the sum of the values of all pixels in imgIn within the
%       neighborhood of input img(x,y) defined by radius
% modified by Eli Bowen 7/2021 for readability, standardization, and performance
function [img] = sumFilter (img, radius)
    assert((size(img, 3) == 1), 'only single-channel images are allowed');

    if numel(radius) == 1
        kernel = ones(2*radius + 1, 'like', img);
    elseif numel(radius) == 4
        kernel = ones(radius(2)+radius(4)+1, radius(1)+radius(3)+1, 'like', img);
    else
        error('unexpected radius');
    end

    img = conv2(img, kernel, 'same');
end