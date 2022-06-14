% Eli Bowen
% converts the R, G, B image to a black vs white, red vs green, yellow vs blue image
% INPUTS
%   img - n_rows x n_cols x 3 RGB image, can be formatted as uint8 (range 0-->255) or double (range 0-->1)
% RETURNS
%   img - n_rows x n_cols x 3 luminance,redvsgreen,yellowvsblue image, same type and range as input
% see also rgb2gray
%converted from java: Frontend.RawOpponent() in ActiveCategorizerCommon on 5/3/2020
function img = RGB2Opponent(img)
    assert(isa(img, 'uint8') || max(img(:)) <= 1, 'image must be uint8 or in the range 0-->1');

    red   = double(img(:,:,1));
    green = double(img(:,:,2));
    blue  = double(img(:,:,3));
    white = max(max(red, green), blue);
    yellow = (white - blue) ./ white; % Y = (255-K-B) / (255-K)

    if isa(img, 'uint8')
        maxVal = 255;
        yellow(isnan(yellow) | yellow == Inf) = maxVal;
        img(:,:,1) = RGB2Luminance(img);                   % white vs black
        img(:,:,2) = uint8((red - green + maxVal) ./ 2);   % red vs green
        img(:,:,3) = uint8((yellow - blue + maxVal) ./ 2); % yellow vs blue
    else
        maxVal = 1;
        yellow(isnan(yellow) | yellow == Inf) = maxVal;
        img(:,:,1) = RGB2Luminance(img);            % white vs black
        img(:,:,2) = (red - green + maxVal) ./ 2;   % red vs green
        img(:,:,3) = (yellow - blue + maxVal) ./ 2; % yellow vs blue
    end
end