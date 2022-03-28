% Eli Bowen 5/1/2021
% code draws a line using the Bresenham line algorithm: https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm
% this hex grid has every other row shifted +0.5 to the right (i.e. rows are intact, cols are diagonalized; i.e. this is the "pointy" / "hesagon corners point up/down" configuration)
% see:
%   "The Generation of Straight Lines on Hexagonal Grids", Yong-Kui 1993
%   ^ we use their pseudocode, but swap rows and cols since we use "pointy" configuration, they use "flat topped"
%   zvold.blogspot.com/2010/01/bresenhams-line-drawing-algorithm-on_26.html
%   www.redblobgames.com/grids/hexagons
% [pos,scaleFactor] = SpreadItemsOn2DHexGridWithRectangularEdges([11,11], 11*11);
% pix = DrawSkinnyLineHex([1,1], [8,3], scaleFactor);
% figure; scatter(pos(:,2), pos(:,1), 'r.'); hold on; scatter(pix(:,2), pix(:,1), 50, 'k*'); axis([0,11,0,11]); xlabel('col'); ylabel('row');
% [pos,scaleFactor] = SpreadItemsOn2DHexGridWithRectangularEdges([64,64], 64*64);
% pix = DrawSkinnyLineHex([1,1], [8,3], scaleFactor);
% figure;
% img = RenderHex2Img([], [64,64], pos, [204,0,0]);
% img = RenderHex2Img(img, [64,64], pix, [255,255,255]);
% imshow(img);
% pt = DrawSkinnyLineHex(obj.line(j,1:2,obj.step), obj.line(j,3:4,obj.step), obj.scaleFactor);
% pos = SpreadItemsOn2DHexGridWithRectangularEdges([64,64], 64*64);
% figure; scatter(pos(:,2), pos(:,1), 'r.'); hold on; xlabel('col'); ylabel('row');
% scatter(pt(:,2), pt(:,1), 50, 'k*');
% scatter(obj.line(j,2,obj.step), obj.line(j,1,obj.step), 50, 'bo')
% scatter(obj.line(j,4,obj.step), obj.line(j,3,obj.step), 50, 'bo')
% UNIT TEST:
% [pos,scaleFactor] = SpreadItemsOn2DHexGridWithRectangularEdges([64,64], 64*64);
% hexCubePos = Pixel2Hex(pos, scaleFactor);
% figure; scatter(pos(:,2), pos(:,1), 'r.'); hold on; scatter(pos(:,1), pos(:,2), 'g.'); xlabel('col'); ylabel('row'); axis(gca, 'equal');
% pt1 = [32,32];
% offset = [];
% offset(1,:) = [2,1];
% offset(2,:) = [-2,-1];
% offset(3,:) = [2,2];
% offset(4,:) = [-2,-2];
% offset(5,:) = [-2,0];
% offset(6,:) = [0,2];
% offset(7,:) = [0,-2];
% offset(8,:) = [1,2];
% offset(9,:) = [-1,-2];
% offset(10,:) = [-1,2];
% offset(11,:) = [1,-2];
% offset(12,:) = [2,-1];
% offset(13,:) = [-2,1];
% offset(14,:) = [-2,2];
% offset(15,:) = [2,-2];
% offset(16,:) = [2,0];
% offset = offset .* 10;
% for i = 1:size(offset, 1)
%     pt2 = pt1 + offset(i,:);
%     pt = DrawSkinnyLineHex(pt1, pt2, scaleFactor);
%     text(pt(end,2)+0.5, pt(end,1), num2str(i));
%     scatter(pt(:,2), pt(:,1), 50, 'k*');
%     
%     temp1 = Hex2Pixel(hexCubePos(Match2GridItemHex(hexCubePos, pt1, scaleFactor),:), scaleFactor);
%     temp2 = Hex2Pixel(hexCubePos(Match2GridItemHex(hexCubePos, pt2, scaleFactor),:), scaleFactor);
%     scatter([pt1(2),pt2(2)], [pt1(1),pt2(1)], 50, 'bo');
%     scatter([temp1(2),temp2(2)], [temp1(1),temp2(1)], 50, 'bd');
%     text(temp2(2)+0.5, temp2(1), num2str(i), 'color', [0,0,0.5]);
% end
% INPUTS:
%   pt1         - 1 x 2 (numeric) 2D position of point 1 (in euclidean / pixel / square coordinates)
%   pt2         - 1 x 2 (numeric) 2D position of point 2 (in euclidean / pixel / square coordinates)
%   scaleFactor - scalar (numeric)
% RETURNS:
%   pix - n_pts x 2 (numeric) coordinates of pixels that should be illuminated by the line
% see also DrawSkinnyLineSqr
function pix = DrawSkinnyLineHex(pt1, pt2, scaleFactor)
    validateattributes(pt1,         {'numeric'}, {'nonempty','numel',2}, 1);
    validateattributes(pt2,         {'numeric'}, {'nonempty','numel',2}, 2);
    validateattributes(scaleFactor, {'numeric'}, {'nonempty','scalar'}, 3);

    pt1 = pt1 ./ scaleFactor;
    pt2 = pt2 ./ scaleFactor;

    pt1(2) = pt1(2) / (sqrt(3)/2);
    pt2(2) = pt2(2) / (sqrt(3)/2);
    pt1(1) = pt1(1) - 0.5 * pt1(2); % must be second
    pt2(1) = pt2(1) - 0.5 * pt2(2); % must be second

    %% way 1
    %% first, set start and end points to be real pixels
    % this hex grid has every other row shifted +0.5 (i.e. rows are intact, cols are diagonalized)
    pt1 = round(pt1); % round to nearest hexagon in the alg's coordinate system
    pt2 = round(pt2); % round to nearest hexagon in the alg's coordinate system

    if pt1(2) > pt2(2) % if category 4, 5, or 6
        temp = pt2;
        pt2 = pt1;
        pt1 = temp;
    end

    d = pt2 - pt1;
    s = sign(d);
    s(s==0) = -1;

    if d(1) > 0 % for category 1 or 4
        iLim = d(1) + d(2);
    elseif d(2) > -d(1) % and d(1) <= 0: for category 2 or 5
        iLim = d(2);
    else % d(2) <= -d(1) and d(1) <= 0: for category 3 or 6
        iLim = -d(1);
    end
    pix = zeros(1+iLim, 2, 'like', pt1);

    x = pt1(1);
    y = pt1(2);
    pix(1,:) = [x,y];
    if d(1) > 0 % for category 1 or 4
        delta = d(1) - d(2);
        for i = 1 : iLim
            if delta > 0
                x = x + s(1);
                delta = delta - 2 * d(2);
            else
                y = y + s(2);
                delta = delta + 2 * d(1);
            end
            pix(1+i,:) = [x,y];
        end
    elseif d(2) > -d(1) % and d(1) <= 0: for category 2 or 5
        delta = 2*d(1) + d(2);
        for i = 1 : iLim
            if delta > 0
                y = y + s(2);
                delta = delta + 2 * d(1);
            else
                x = x + s(1);
                y = y + s(2);
                delta = delta + 2 * (d(1) + d(2));
            end
            pix(1+i,:) = [x,y];
        end
    else % d(2) <= -d(1) and d(1) <= 0: for category 3 or 6
        delta = d(1) + 2*d(2);
        for i = 1 : iLim
            if delta <= 0
                x = x + s(1);
                delta = delta + 2 * d(2);
            else
                x = x + s(1);
                y = y + s(2);
                delta = delta + 2 * (d(1) + d(2));
            end
            pix(1+i,:) = [x,y];
        end
    end

    %% way 2 (not 100% working)
%     % http://www-cs-students.stanford.edu/~amitp/Articles/HexLOS.html
%     % assume abs(dx) >= abs(dy), it's symmetric otherwise
%     %array2hex(x,y) = [x - floor(y/2),x + ceil(y/2)];
%     %hex2array(x,y) = [floor((x+y)/2),y - x];
%     pt1 = flip(pt1);
%     pt2 = flip(pt2);
% %     pt1 = [pt1(2) - pt1(1)/2,pt1(2) + pt1(1)/2];
% %     pt2 = [pt2(2) - pt2(1)/2,pt2(2) + pt2(1)/2];
% %     pt1 = [(pt1(1)+pt1(2))/2,pt1(2) - pt1(1)];
% %     pt2 = [(pt2(1)+pt2(2))/2,pt2(2) - pt2(1)];
% %     pt1 = [pt1(1) - floor(pt1(2)/2),pt1(1) + ceil(pt1(2)/2)];
% %     pt2 = [pt2(1) - floor(pt2(2)/2),pt2(1) + ceil(pt2(2)/2)];
%     pt1 = round(pt1); % round to nearest hexagon in the alg's coordinate system
%     pt2 = round(pt2); % round to nearest hexagon in the alg's coordinate system
% 
%     d = pt2 - pt1;
%     s = sign(d);
%     s(s==0) = 1;
% 
%     sig = (sign(d(1)) ~= sign(d(2))); % this is (2); this line changes from "==" to "!=" if hexagons are not stacked vertically
%     d = abs(d);
%     factor = d(1) / 2;
% 
%     if d(1) > 0 % for category 1 or 4
%         iLim = d(1) + d(2);
%     elseif d(2) > -d(1) % and d(1) <= 0: for category 2 or 5
%         iLim = d(2);
%     else % d(2) <= -d(1) and d(1) <= 0: for category 3 or 6
%         iLim = -d(1);
%     end
%     pix = zeros(1+iLim, 2, 'like', pt1);
% 
%     x = pt1(1);
%     y = pt1(2);
%     pix(1,:) = [x,y];
% %     while x ~= pt2(1) || y ~= pt2(2)
%     for i = 1:iLim
%         factor = factor + d(2);
%         if factor >= d(1)
%             factor = factor - d(1); % make a "diagonal move" in grid (ie vertical or horizontal)
%             if sig % vertical move: 2 moves in 1
%                 x = x + s(1); % add 1 in the appropriate sign
%                 y = y + s(2);   
%             else % horizontal move: 2 moves in 2
%                 x = x + s(1); % doesn't matter which increases first
%                 pix(end+1,:) = [x,y];
%                 y = y + s(2);
%             end
%         else
%             x = x + s(1);
%         end
%         pix(end+1,:) = [x,y];
%     end
% %     pix = [pix(:,1) - floor(pix(:,2)/2),pix(:,1) + ceil(pix(:,2)/2)];
% %     pix = [(pix(:,1)+pix(:,2))/2,pix(:,2) - pix(:,1)];
% % %     pix(:,1) = pix(:,1) + 0.5 .* pix(:,2); % must be first
% % %     pix(:,2) = pix(:,2) .* (sqrt(3)/2);
%     pix(:,2) = pix(:,2) + 0.5 .* pix(:,1); % must be first
%     pix(:,1) = pix(:,1) .* (sqrt(3)/2);
% %     pix(:,2) = pix(:,2) ./ (sqrt(3)/2);
%     pix = fliplr(pix);

    %% convert this paper's unique coordinates to pixel coordinates
    pix(:,1) = pix(:,1) + 0.5 .* pix(:,2); % must be first
    pix(:,2) = pix(:,2) .* (sqrt(3)/2);

    pix = pix .* scaleFactor;
end