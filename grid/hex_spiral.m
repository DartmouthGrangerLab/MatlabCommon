% Eli Bowen
% 5/21/2021
% modified from www.redblobgames.com/grids/hexagons
% INPUTS:
%   center - n_items x 3 (numeric) center position in hexagon cube coordinates
%   radius - scalar (numeric)
% RETURNS:
%   x - n_items x 3 (numeric) hexagon cube coordinates
function [x] = hex_spiral(center, radius)
    validateattributes(center, 'numeric', {'nonempty','2d','ncols',3});
    validateattributes(radius, 'numeric', {'nonempty','scalar','positive','integer'});
    n_items = size(center, 1);

    x = zeros((1 + sum((1:radius) .* 6)) * n_items, 3);
    x(1:n_items,:) = center;
    count = n_items;
    for i = 1 : radius
        x(count + (1:i*6*n_items),:) = hex_ring(center, i);
        count = count + i*6*n_items;
    end

    assert(sum(x(:)) == 0); % valid cubic hex coordinates sum to 0 (else we have >1 cubic coord matching same 2D coord)
end