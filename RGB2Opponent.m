%Eli Bowen
%Converts the R, G, B image to a black vs white, red vs green, yellow vs blue image
%@param image 	width x height x RGB
%@return width x height x 3
%converted from java: Frontend.RawOpponent() in ActiveCategorizerCommon on 5/3/2020
function [image] = RGB2Opponent (image)
    assert(max(image(:)) <= 1);
    
    red   = image(:,:,1) .* 255;
    green = image(:,:,2) .* 255;
    blue  = image(:,:,3) .* 255;
    luminance = 0.2989 .* red + 0.5870 .* green + 0.1140 .* blue; %http://gimp-savvy.com/BOOK/index.html?node54.html
    white = max(max(red, green), blue);
    yellow = (white - blue) ./ white; %Y = (255-B-K) / (255-K)
    yellow(isnan(yellow) | yellow == Inf) = 1;
    
    image(:,:,1) = luminance; %whitevsblack
    image(:,:,2) = (red - green + 255) ./ 2; %redvsgreen
    image(:,:,3) = (yellow - blue + 255) ./ 2; %yellowvsblue
end