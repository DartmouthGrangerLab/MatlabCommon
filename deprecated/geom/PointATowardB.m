% deprecated
function dir = PointATowardB(a, b)
    assert(numel(a) == 2 && numel(b) == 2);

    x = b(1) - a(1);
    y = b(2) - a(2);

	dir = atan(y ./ x) ./ pi .* 180;

    % now correct for how dir is always -90-->90
    dir(x<0 & y<0) = dir(x<0 & y<0) + 180;
    dir(x<0 & y>0) = dir(x<0 & y>0) + 180; % it actually substracts
    dir(x>0 & y<0) = (dir(x>0 & y<0) + 90) + 270; % it actually substracts
%     if x < 0 && y < 0
%         dir = dir + 180;
%     elseif x < 0
%         dir = dir + 180; % it actually substracts
%     elseif y < 0
%         dir = (dir + 90) + 270; % it actually substracts
%     end

    % handle special cases
    dir(x==0 & y==0) = 0;
    dir(x==0 & y>0) = 90;
    dir(x==0 & y<0) = 270;
    dir(x>0 & y==0) = 0;
    dir(x<0 & y==0) = 180;
%     if x == 0 % special case
%         if y > 0
%             dir = 90;
%         elseif y == 0
%             dir = 0;
%         else
%             dir = 270;
%         end
%         return;
%     elseif y == 0 % special case
%         if x >= 0
%             dir = 0;
%         else
%             dir = 180;
%         end
%         return;
%     end
end