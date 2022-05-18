%Eli Bowen
%8/6/2020
%converts an RGB image to grayscale using a standard perceptual luminance formula
%http://gimp-savvy.com/BOOK/index.html?node54.html
%ok this is basically matlab's rgb2gray()
%INPUTS:
%   img - nRows x nCols x 3 RGB image, can be formatted as uint8 (range 0-->255) or double (range 0-->1)
%RETURNS:
%   img - nRows x nCols x 1 grayscale image, same type and range as input
function [img] = RGB2Luminance (img)
    assert(isa(img, 'uint8') || max(img(:)) <= 1, 'image must be uint8 or in the range 0-->1');
    
    if isa(img, 'uint8')
        img = double(img);
        img = 0.2989 .* img(:,:,1) + 0.5870 .* img(:,:,2) + 0.1140 .* img(:,:,3);
        img = uint8(img);
    else
        img = 0.2989 .* img(:,:,1) + 0.5870 .* img(:,:,2) + 0.1140 .* img(:,:,3);
    end
end