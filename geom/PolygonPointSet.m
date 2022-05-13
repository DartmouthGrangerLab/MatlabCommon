% Eli Bowen 8/17/2020
% define shapes (in format accepted by matlab's insertShape())
% INPUTS:
%   polyRadius   - scalar (numeric) polygon radius in units of pixels
%   puckerFactor - OPTIONAL (default = 1 aka none) scalar (numeric) squeeze radius this much in one direction
% RETURNS:
%   pointSet - cell array of sets of points, generally 2 x n_points numerics
function pointSet = PolygonPointSet(polyRadius, puckerFactor)
    validateattributes(polyRadius, {'numeric'}, {'nonempty','scalar','positive'}, 1);
    if ~exist('puckerFactor', 'var') || isempty(puckerFactor)
        puckerFactor = 1; % squeeze radius this much in one direction
    end

    pointSet = cell(1, 8);

    % circle
    pointSet{1} = [0,0]; % polygon with 1 side handled specially
%     pointSet{1} = [0,0,polyRadius]; % polygon with 1 side handled specially

    % triangle
    pointSet{3} = [-1,-1;...
        1,0;...
        -1,1;...
        -1,-1];
    pointSet{3} = pointSet{3}'; % transpose because var must be 2 x nPoints so points{i}(:) won't break the ordering later

    % rectangle
    pointSet{4} = [-1,-1;...
        -1,1;...
        1,1;...
        1,-1];
    pointSet{4} = pointSet{4}'; % transpose because var must be 2 x nPoints so points{i}(:) won't break the ordering later

    % pentagon
    pointSet{5} = [cos(0),sin(0);... % y = 0
        cos(1*pi*2/5),sin(1*pi*2/5);... % y > 0
        cos(2*pi*2/5),sin(2*pi*2/5);... % y > 0
        cos(3*pi*2/5),sin(3*pi*2/5);... % y < 0
        cos(4*pi*2/5),sin(4*pi*2/5);... % y < 0
        cos(0),sin(0)];
    pointSet{5} = pointSet{5}'; % transpose because var must be 2 x nNoints so points{i}(:) won't break the ordering later

    % hexagon
    pointSet{6} = [-1,0;...
        -1/2,sqrt(3)/2;...
        1/2,sqrt(3)/2;...
        1,0;...
        1/2,-sqrt(3)/2;...
        -1/2,-sqrt(3)/2;...
        -1,0];
    pointSet{6} = pointSet{6}'; % transpose because var must be 2 x nPoints so points{i}(:) won't break the ordering later
    R = [cos(pi/2),sin(pi/2);-sin(pi/2),cos(pi/2)]; % 2D rotation matrix (90 degrees)
    pointSet{6} = R * pointSet{6}; % rotate each point about the origin (so flat size faces "forward")

    % septagon (careful using, because at small resolutions it's just a circle)
    pointSet{7} = [cos(0),sin(0);... % y = 0
        cos(1*pi*2/7),sin(1*pi*2/7);... % y > 0
        cos(2*pi*2/7),sin(2*pi*2/7);... % y > 0
        cos(3*pi*2/7),sin(3*pi*2/7);... % y > 0
        cos(4*pi*2/7),sin(4*pi*2/7);... % y < 0
        cos(5*pi*2/7),sin(5*pi*2/7);... % y < 0
        cos(6*pi*2/7),sin(6*pi*2/7);... % y < 0
        cos(0),sin(0)];
    pointSet{7} = pointSet{7}'; % transpose because var must be 2 x nPoints so points{i}(:) won't break the ordering later

    % octagon (careful using, because at small resolutions it's just a circle)
    pointSet{8} = [cos(0),sin(0);... % y = 0
        cos(1*pi*2/8),sin(1*pi*2/8);...
        cos(2*pi*2/8),sin(2*pi*2/8);...
        cos(3*pi*2/8),sin(3*pi*2/8);...
        cos(4*pi*2/8),sin(4*pi*2/8);...
        cos(5*pi*2/8),sin(5*pi*2/8);...
        cos(6*pi*2/8),sin(6*pi*2/8);...
        cos(7*pi*2/8),sin(7*pi*2/8);...
        cos(0),sin(0)];
    pointSet{8} = pointSet{8}'; % transpose because var must be 2 x nPoints so points{i}(:) won't break the ordering later
    R = [cos(pi/8),sin(pi/8);-sin(pi/8),cos(pi/8)]; % 2D rotation matrix (90 degrees)
    pointSet{8} = R * pointSet{8}; % rotate each point about the origin (so flat size faces "forward")

    for i = 3:numel(pointSet)
        pointSet{i} = pointSet{i} .* polyRadius;
        pointSet{i}(2,:) = pointSet{i}(2,:) .* puckerFactor;
        pointSet{i} = fliplr(pointSet{i}); % shapes are pointed sideways - swap x and y
    end
    pointSet{4} = floor(pointSet{4}); % align sides with pixels for added clarity

%     figure;
%     scaleFactor = 0.5;
%     spriteWidth = 2 * polyRadius * scaleFactor + 4;
%     blankSprite = zeros(spriteWidth, spriteWidth, 3, 'uint8');
%     dir = 0;
%     for poly = 3:numel(pointSet)
%         R = [cos(dir),sin(dir);-sin(dir),cos(dir)];
%         S = [scaleFactor,0;0,scaleFactor];
%         points = pointSet{poly};
%         for j = 1:size(points, 2)
%             points(:,j) = S * R * points(:,j);
%         end
%         points = points + spriteWidth / 2;
%         sprite = uint8(insertShape(blankSprite, 'FilledPolygon', points(:)', 'Color', 'w', 'Opacity', 1, 'SmoothEdges', false));
%         sprite = uint8(insertShape(sprite, 'FilledCircle', [spriteWidth/2,spriteWidth/2,spriteWidth/16], 'Color', [0.5,0.5,0.5], 'Opacity', 1, 'SmoothEdges', false));
% %         sprite = imresize(sprite, 1, 'bilinear');
%         subplot(2, 3, poly-2);
%         imagesc(sprite);title(num2str(poly));
%     end
end