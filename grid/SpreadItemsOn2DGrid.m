% Eli Bowen
% 9/1/2020
% [pos,scaleFactor] = SpreadItemsOn2DGrid(10*10, [10,10], 'hex');
% figure; scatter(pos(:,2), pos(:,1)); xlabel('c'); ylabel('r');
% [pos,scaleFactor] = SpreadItemsOn2DGrid(10*10, 10, 'hex');
% figure; scatter(pos(:,2), pos(:,1)); xlabel('c'); ylabel('r');
% [pos,scaleFactor] = SpreadItemsOn2DGrid(10*10, [10,10], 'sqr');
% figure; scatter(pos(:,2), pos(:,1)); xlabel('c'); ylabel('r');
% INPUTS:
%   n_items  - scalar (numeric)
%   sz       - 1 x 2 (numeric) size of the rectangle along [row,col] dimensions (not to be confused with nRows / nCols)
%   gridMode - (char) 'sqr' or 'hex'
% RETURNS:
%   pos         - n_items x 2 (numeric) row,col position of each item in euclidean / square coordinates
%   scaleFactor - scalar (numeric) a unit hex grid has been multiplied by this scale factor
function [pos,scaleFactor] = SpreadItemsOn2DGrid(n_items, sz, gridMode)
    validateattributes(n_items,  'numeric', {'nonempty','scalar','positive','integer'});
    validateattributes(sz,       'numeric', {'nonempty','vector','positive'});
    validateattributes(gridMode, 'char',    {'nonempty','vector'});

    %% compute starting square grid
    if numel(sz) == 1 % circular boundary
        % compute approximate (slightly-too-big) diameter
        validateattributes(sz, 'numeric', {'integer'}); % currently we only support integer sizes (not sure why)
        diameter = 2 * ceil(sqrt(n_items / pi)) + 2; % area of circle should be ~n_items (pi*r^2 = area); + 2 for some padding
        if mod(diameter, 2) == 0 % if even
            diameter = diameter + 1; % make odd
        end
        rLim = diameter + 1;
        cLim = diameter + 1;
    elseif numel(sz) == 2 % rectangular boundary
        if strcmp(gridMode, 'sqr')
            %scale = sqrt(n_items / (sz(1) * sz(2)));
            scale = n_items / (sz(1) * sz(2)); % n_items / scale = rowSize * colSize
            error('^ which is it, sqrt or not?');
            rLim = ceil(sz(1) * scale);
            cLim = ceil(sz(2) * scale);
        elseif strcmp(gridMode, 'hex')
            scale = sqrt(n_items / (sz(1) * sz(2) * (2/sqrt(3)))); % n_items / scale^2 = rowSz * colSz
            rLim = ceil(sz(1) * scale);
            cLim = ceil(sz(2) * scale * (2/sqrt(3)));
        else
            error('unexpected gridMode');
        end
        
        if mod(cLim, 2) == 1 % if odd
            cLim = cLim + 1; % must be even (for math below, size(x, 2) must be even)
        end
    else
        error('unexpected sz');
    end

    [c,r] = meshgrid(0:cLim-1, 0:rLim-1); % yes, matlab did it all backwards

    % convert square grid to hexagonal
    % every other row is shifted +0.5 to the right
    % (i.e. rows are intact, cols are diagonalized)
    % (i.e. this is the "pointy" / "hexagon corners point up/down" configuration)
    r = r + repmat([0,0.5], [rLim,cLim/2]);
    c = c .* (sqrt(3) / 2);

    %% crop excess items
    % remove most distant items until we get n_items
    if numel(sz) == 1 % circular boundary
        % crop square to circle
        center = (floor(diameter / 2) - 1) .* [1,1];
        distsSq = (c(:)-center(1)).^2 + (c(:)-center(2)).^2; % squared euclidean dist
        error('^verify: should this have a r variable?');
        sortVar = distsSq; % remove most distant items until we get n_items
    elseif numel(sz) == 2 % rectangular boundary
        % if possible, remove an entire <largerdim> - shrinking larger dim will cause less stretching of the hex grid when we fit it into a rowSize x colSize rectangle
        if sz(1) > sz(2) % more rows than columns
            if (rLim - 1) * cLim >= n_items % if we can remove an entire row
                r = r(1:end-1,:);
                c = c(1:end-1,:);
            end
            sortVar = c(:)'; % remove *some* of the items on the last column
        else % more columns than rows, or square
            if rLim * (cLim - 1) >= n_items % if we can remove an entire column
                r = r(:,1:end-1);
                c = c(:,1:end-1);
            end
            sortVar = r(:)'; % remove *some* of the items on the last row
        end
    else
        error('unexpected sz');
    end

    pos = [r(:),c(:)];
    [~,idx] = sort(sortVar, 'descend');
    idx = idx(1:(numel(idx)-n_items));
    pos(idx,:) = []; % remove top distances (linear indexing)

    %% translate and scale positions to match desired size
    if numel(sz) == 1 % circular boundary
        % match desired diameter
        pos(:,1) = pos(:,1) - min(pos(:,1));
        pos(:,2) = pos(:,2) - min(pos(:,2));
        distsSq(idx) = [];
        scaleFactor = sz / (2*sqrt(max(distsSq)));
    elseif numel(sz) == 2 % rectangular boundary
        % fit within 0-->nX and 0-->nY
        % sz(1)/max(pos(:,1)) approximately == sz(2)/max(pos(:,2))
        % but given small diffs we take the larger of the two so that no area of the grid is un-covered
        % (alternative would be smaller of the two so that no neurons are out of bounds)
        if strcmp(gridMode, 'sqr')
            scaleFactor = max(sz(1) / max(pos(:,1)), sz(2) / max(pos(:,2)));
        elseif strcmp(gridMode, 'hex')
            % below, -0.5 is important: even numbered columns have rows that are shifted to the right, so odd numbered columns have a tiny gap right at the edge where scaled [r,c] points round to hexagons outside the bounds of sz (these hexagons don't exist)
            scaleFactor = max(sz(1) / (max(pos(:,1))-0.5), sz(2) / max(pos(:,2)));
        else
            error('unexpected gridMode');
        end
    else
        error('unexpected sz');
    end

    pos = pos .* scaleFactor;

    %% validate
    assert(size(pos, 1) == n_items);
end