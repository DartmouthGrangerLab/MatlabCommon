% Eli Bowen 5/3/2021
% INPUTS:
%   img    - OPTIONAL - if empty, we'll create one of size 3.*gridSize; if populated, we'll render onto it
%   gridSz - if scalar, grid has a circular boundary of diameter gridSz. if 1 x 2, grid has a rectangular boundary of [rowSz,colSz]
%   pos    - n_items x 2 (numeric) list of 2D positions of each item
%   color  - double (ranged 0-->1) or uint8 matrix of size n_items x 1 (grayscale) or n_items x 3 (color) - color for each item, or one color for all items
% RETURNS:
%   img
function img = RenderHex2Img(img, gridSz, pos, color)
    if ~isempty(img)
        validateattributes(img, 'uint8', {});
    end
    validateattributes(gridSz, 'numeric',          {'nonempty','vector','positive'});
    validateattributes(pos,    'numeric',          {'nonnegative'});
    validateattributes(color,  {'uint8','double'}, {'nonempty'});
    if numel(gridSz) == 1
        gridSz = [gridSz,gridSz];
    end
    assert(numel(gridSz) == 2);
    if isa(color, 'double')
        color = uint8(255 .* color);
    end
    scale = 3;
    n_chan = size(color, 2);
    n_items = size(pos, 1);
    
    if isempty(pos)
        if isempty(img)
            imgRes = (gridSz + 1) .* scale; % +1 because we usually have pixels at both position 0 and position gridSize
            img = zeros(imgRes(1), imgRes(2), n_chan, 'uint8');
        end
        return
    end
    assert(size(pos, 2) == 2);
    assert(size(color, 1) == size(pos, 1) || size(color, 1) == 1);
    assert(n_chan == 1 || n_chan == 3);

    if isempty(img)
        imgRes = (gridSz + 1) .* scale; % +1 because we usually have pixels at both position 0 and position gridSize
        img = zeros(imgRes(1), imgRes(2), n_chan, 'uint8');
    else
        imgRes = [size(img, 1),size(img, 2)];
        assert(size(img, 3) == n_chan); % if color's grayscale, the img should be too
    end

    pos = 1 + floor(pos .* imgRes ./ (gridSz + 1));
    assert(all(pos(:) >= 1) && all(pos(:,1) <= size(img, 1)) && all(pos(:,2) <= size(img, 2)));

    if size(color, 1) == 1
        for i = 1 : n_items
            img(pos(i,1),pos(i,2),:) = color;
        end
    else
        for i = 1 : n_items
            img(pos(i,1),pos(i,2),:) = color(i,:);
        end
    end
    %^NOTE: sub2ind here is NOT faster
end