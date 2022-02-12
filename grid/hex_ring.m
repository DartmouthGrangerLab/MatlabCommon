% Eli Bowen
% 5/21/2021
% modified from www.redblobgames.com/grids/hexagons
% a=Hex2Pixel(hex_ring(gridPos, 1), scaleFactor);b=Hex2Pixel(gridPos,:), scaleFactor);figure;scatter(a(:,1),a(:,2));hold on;scatter(b(:,1),b(:,2))
% INPUTS:
%   center - n_items x 3 (numeric) center position in hexagon cube coordinates
%   radius - scalar (numeric)
% RETURNS:
%   x - n_items x 3 (numeric) hexagon cube coordinates
function [x] = hex_ring(center, radius)
    validateattributes(center, 'numeric', {'nonempty','2d','ncols',3});
    validateattributes(radius, 'numeric', {'nonempty','scalar','positive','integer'});
    n_items = size(center, 1);

    cubeDirections = [1,-1,0;1,0,-1;0,1,-1;-1,1,0;-1,0,1;0,-1,1];
    x = zeros(radius * 6 * n_items, 3);
    count = 1;
    for k = 1 : n_items
        curr = center(k,:) + cubeDirections(5,:) .* radius; % 5 determined by trial and error
        for i = 1 : 6
            for j = 1 : radius
                x(count,:) = curr;
                curr = curr + cubeDirections(i,:); % in cube coordinate system, cube coordinate addition is just vector arithmetic
                count = count + 1;
            end
        end
    end

    assert(sum(x(:)) == 0); % valid cubic hex coordinates sum to 0 (else we have >1 cubic coord matching same 2D coord)
end