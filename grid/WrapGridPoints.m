% Eli Bowen
% 5/24/2021
% INPUTS:
%   pt          - n_items x d (numeric)
%   sz          - 1 x 2 (numeric)
%   scaleFactor - scalar (numeric)
% RETURNS:
%   pt - n_items x d (numeric)
function [pt] = WrapGridPoints(pt, sz, scaleFactor)
    validateattributes(pt,          'numeric', {'nonempty','2d'});
    validateattributes(sz,          'numeric', {'nonempty','vector','numel',2,'positive'});
    validateattributes(scaleFactor, 'numeric', {'nonempty','scalar'});

    is_hex_cube_cords = false;
    if size(pt, 2) == 3 % hexagon cube coordinates
        assert(sum(pt(:)) == 0); % valid cubic hex coordinates sum to 0 (else we have >1 cubic coord matching same 2D coord)
        pt = Hex2Pixel(pt, scaleFactor);
        is_hex_cube_cords = true;
    end

    belowLim = (pt < 0);
    aboveLim = (pt > sz(:)'); % implicit expansion
    pt(belowLim(:,1),1) = pt(belowLim(:,1),1) + sz(1);
    pt(belowLim(:,2),2) = pt(belowLim(:,2),2) + sz(2);
    pt(aboveLim(:,1),1) = pt(aboveLim(:,1),1) - sz(1);
    pt(aboveLim(:,2),2) = pt(aboveLim(:,2),2) - sz(2);

    if is_hex_cube_cords
        pt = Pixel2Hex(pt, scaleFactor);
        assert(sum(pt(:)) == 0); % valid cubic hex coordinates sum to 0 (else we have >1 cubic coord matching same 2D coord)
    end
end