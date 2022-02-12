% Eli Bowen
% 5/1/2021
% we're using "cube coordinates" from www.redblobgames.com/grids/hexagons and the "pointy" hexagon configuration
% pseudocode also from www.redblobgames.com/grids/hexagons
% INPUTS:
%   pt
% RETURNS:
%   pt
function [pt] = hex_round(pt)
    validateattributes(pt, 'numeric', {'nonempty','2d','ncols',3});
    assert(sum(ret) == 0); % valid cubic hex coordinates sum to 0 (else we have >1 cubic coord matching same 2D coord)

    r = round(pt);
    d = abs(r - pt);
    pt = r;

    cond1 = (d(:,1) > d(:,2)) & (d(:,1) > d(:,3));
    cond2 = ~cond1 & (d(:,2) > d(:,3));
    cond3 = ~cond1 & ~cond2;
    pt(cond1,1) = -pt(cond1,2) - pt(cond1,3);
    pt(cond2,2) = -pt(cond2,1) - pt(cond2,3);
    pt(cond3,3) = -pt(cond3,1) - pt(cond3,2);

    assert(sum(pt(:)) == 0); % valid cubic hex coordinates sum to 0 (else we have >1 cubic coord matching same 2D coord)
end