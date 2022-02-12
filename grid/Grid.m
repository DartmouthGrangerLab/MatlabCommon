% Eli Bowen
% 6/4/2021
% this class represents a grid of items
classdef Grid < handle
    properties (SetAccess=immutable)
        sz                         % if scalar, sz is the diameter of a circle; if 1 x 2, sz is [n_rows,n_cols] of a rectangle
        mode        (1,:) char     % (char) 'hex', 'sqr'
        is_wrapped  (1,1) logical  % if true, wrap points around the edges of the grid; if false, will throw an error when points are out of the bounds specified by obj.sz
        scaleFactor (1,1) double   % amount that unit grid is scaled to fit into sz
        pos                        % n_items x 2 (numeric) 2D euclidean position of each item
        gridPos                    % n_items x 3 (numeric) hex cube position of each item
    end
    properties (SetAccess=private, Transient=true) % cache for precomputed values
        cache struct = struct()
    end
    properties (Dependent) % computed, derivative properties
        n_items % scalar (double) - number of items in the grid
    end


    methods
        function [obj] = Grid(n_items, sz, mode, is_wrapped) % constructor
            validateattributes(n_items,    'numeric', {'nonempty','scalar','positive','integer'});
            validateattributes(sz,         'numeric', {'nonempty','positive'});
            validateattributes(mode,       'char',    {'nonempty','vector'});
            validateattributes(is_wrapped, 'logical', {'nonempty','scalar'});
            if is_wrapped && numel(sz) == 1
                error('wrapping with circular-boundary grids not yet implemented');
            end

            obj.sz = sz;
            obj.mode = mode;
            obj.is_wrapped = is_wrapped;
            [obj.pos,obj.scaleFactor] = SpreadItemsOn2DGrid(n_items, obj.sz, obj.mode);
            if strcmp(obj.mode, 'hex')
                obj.gridPos = Pixel2Hex(obj.pos, obj.scaleFactor); % integer hex coordinates
            elseif strcmp(obj.mode, 'sqr')
                obj.gridPos = [];
            else
                error('unexpected mode');
            end

            assert(any(all(obj.pos == [0,0], 2))); % for simplicity, should be able to assume we have an item be at the origin
        end


        % INPUTS:
        %   pt - queryHexCubePos - n_queries x 2 (euclidean coordinates) or 3 (already in hex cube coordinates) - position of each query
        % RETURNS:
        %   idx - index of the matching grid item for each query (indexes into 1:n_items)
        function [idx] = Match2GridItem(obj, pt)
            if strcmp(obj.mode, 'hex') && size(pt, 2) == 3
                pt = Hex2Pixel(pt, obj.scaleFactor);
            end
            validateattributes(pt, 'numeric', {'integer','ncols',2});

            if obj.is_wrapped
                pt = WrapGridPoints(pt, obj.sz, obj.scaleFactor);
            end

            [~,idx] = min(pdist2(obj.pos, pt, 'squaredeuclidean'), [], 1); % find indices of items that the drawing selected
        end


        % gets
        function [x] = get.n_items(obj)
            x = size(obj.pos, 1);
        end


        % get all neighbors of the grid items specified by param select
        % INPUTS:
        %   radius - neighborhood radius, in units of position DIVIDED by scaleFactor, i.e. units of min pdist between items
        %   select - logical mask, numeric indices, or 'all'
        % RETURNS:
        %   x - n_neighbors x n_items_in_select (int-valued numeric) index
        function [x] = GetNeighborIdx(obj, radius, select)
            validateattributes(radius, 'double', {'nonempty','scalar'});
            assert(radius >= 1, 'radius < 1 yields no neighbors');
            
            if ~isfield(obj.cache, 'neighbor_idx') % must (re)build cache
                obj.cache.neighbor_idx = obj.GetNeighborIdxAll(radius);
            end
            x = obj.cache.neighbor_idx;
            
            if islogical(select) || isnumeric(select)
                x = x(:,select);
            end
        end


        % get all neighbors of each grid item
        % INPUTS:
        %   radius - neighborhood radius, in units of position DIVIDED by scaleFactor, i.e. units of min pdist between items
        % RETURNS:
        %   idx - n_neighbors x n_items_in_select (int-valued numeric)
        function [idx] = GetNeighborIdxAll(obj, radius)
            validateattributes(radius, 'double', {'nonempty','scalar'});
            assert(radius >= 1, 'radius < 1 yields no neighbors');
            assert(strcmp(obj.mode, 'hex')); % currently this function only supports hex grids
            
            relativeGridPos = hex_spiral([0,0,0], ceil(radius)); % n_neighbors x 3 (int-valued numeric)
            relativeGridPos(1,:) = []; % remove self
            if mod(radius, 1) ~= 0 % if radius isn't a nice round integer
                relativeGridPos = relativeGridPos(pdist2(Hex2Pixel(relativeGridPos, 1), Hex2Pixel([0,0,0], 1)) <= radius+eps,:); % nNeighbors x 3 (int-valued numeric)
            end
            
            idx = zeros(size(relativeGridPos, 1), obj.n_items);
            for i = 1 : obj.n_items
                idx(:,i) = obj.Match2GridItem(relativeGridPos + obj.gridPos(i,:)); % implicit expansion
            end
        end


        % is_wrapped is ignored for this calculation - this is the angle were the item not wrapped
        % INPUTS:
        %   radius - scalar (double) neighborhood radius, in units of position DIVIDED by scaleFactor, i.e. units of min pdist between items
        % RETURNS:
        %   angle - 1 x n_neighbors (numeric) angle of the line from any item to each of its neighbors in degrees (ranged 0-->359)
        function [angle] = GetNeighborRelativeAngle(obj, radius)
            validateattributes(radius, 'double', {'nonempty','scalar'});
            assert(radius >= 1, 'radius < 1 yields no neighbors');
            assert(strcmp(obj.mode, 'hex')); % currently this function only supports hex grids

            relativeGridPos = hex_spiral([0,0,0], ceil(radius)); % n_neighbors x 3 (int-valued numeric)
            relativeGridPos(1,:) = []; % remove self
            if mod(radius, 1) ~= 0 % if radius isn't a nice round integer
                relativeGridPos = relativeGridPos(pdist2(Hex2Pixel(relativeGridPos, 1), Hex2Pixel([0,0,0], 1)) <= radius+eps,:); % n_neighbors x 3 (int-valued numeric)
            end

            relativePos = Hex2Pixel(relativeGridPos, obj.scaleFactor); % n_neighbors x 2 (numeric)
            dx = relativePos(:,2);
            dy = relativePos(:,1);
            angle = atand(dy ./ dx); % angle of line from the origin to each grid item indexed by radSqrt3Idx
            angle(dx<0) = angle(dx<0) + 180;
            angle(angle<0) = angle(angle<0) + 360; % now ranged 0-->359
        end


        %COMMENTED OUT ONLY BECAUSE UNUSED AND UNTESTED
%         % modified from www.redblobgames.com/grids/hexagons
%         % uses cube coordinate system for hexagons
%         % INPUTS:
%         %   pt1
%         %   pt2
%         function [ret] = hex_distance (obj, pt1, pt2)
%             if size(pt1, 2) == 2
%                 pt1 = hex_round(Pixel2Hex(pt1, obj.scaleFactor));
%             end
%             validateattributes(pt1, 'numeric', {'integer','ncols',3});
%             if size(pt2, 2) == 2
%                 pt2 = hex_round(Pixel2Hex(pt2, obj.scaleFactor));
%             end
%             validateattributes(pt2, 'numeric', {'integer','ncols',3});
% 
%             ret = sum(abs(pt1 - pt2)) ./ 2;
%             % below supposedly identical to above (untested)
%         %     ret = max(abs(pt1 - pt2));
%         end
    end
end