% Eli Bowen
% 7/2021
% adapted from the original hmax code, not really changed functionally
% INPUTS:
%   img - matrix (numeric)
%   sqfilter - 2D square-shaped matrix (numeric) - generate with InitGabor()
%   isIncludeBorder - scalar (logical) - should we include the image border in the return value?
function [img] = ApplyGaborFilter (img, sqfilter, isIncludeBorder)
    USECONV2 = true; % should be faster if true
    sz = size(sqfilter, 1); % same as size(sqfilter, 2)

    if USECONV2 % not 100% compatible but 20% faster at least
        img = abs(conv2(img, sqfilter(end:-1:1,end:-1:1), 'same')); % flip to use conv2 instead of imfilter
    else
        img = abs(imfilter(img, sqfilter, 'symmetric', 'same', 'corr'));
    end

    % remove borders
    if ~isIncludeBorder
        img = unpadImage(img, [(sz+1)/2,(sz+1)/2,(sz-1)/2,(sz-1)/2]);
        img = padarray(img, [(sz+1)/2,(sz+1)/2], 0, 'pre');
        img = padarray(img, [(sz-1)/2,(sz-1)/2], 0, 'post');
    end

    % normalize
    norm = sumFilter(img .^ 2, (sz-1)/2) .^ 0.5;
    norm = norm + ~norm; % avoid divide by zero later
    img = im2double(img) ./ norm;
end