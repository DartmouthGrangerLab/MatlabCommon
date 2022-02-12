% Eli Bowen
% 5/1/2021
% we're using "cube coordinates" from www.redblobgames.com/grids/hexagons and the "pointy" hexagon configuration
% INPUTS:
%   pt - n_points x 3 (numeric)
%   scaleFactor - scalar (numeric)
% RETURNS:
%   pt - n_points x 2 (numeric)
function [pt] = Hex2Pixel(pt, scaleFactor)
    validateattributes(pt, 'numeric', {'nonempty','2d','ncols',3});
    validateattributes(scaleFactor, 'numeric', {'nonempty','scalar'});

    % convert cube coordinates to axial coordinates
    q = pt(:,1);
    r = pt(:,3);

    x = q + 0.5 .* r;
    y = r .* (sqrt(3)/2);
%     x = sqrt(3) .* q + sqrt(3)/2 .* r;
%     y = 3/2 .* r;

    pt = [x(:),y(:)] .* scaleFactor;
end