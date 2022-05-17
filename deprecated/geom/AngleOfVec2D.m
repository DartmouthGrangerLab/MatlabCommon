% deprecated
function theta = AngleOfVec2D(u, resultFormat)
    validateattributes(u, {'numeric'}, {'nonempty','2d'}, 1);
    validateattributes(resultFormat, {'char'}, {'nonempty'}, 2);
    assert(isempty(u) || size(u, 1) == 2); % must be 2D

    cosTheta = max(min(u(1,:) ./ vecnorm(u), 1), -1); % dot(u, [1,0]) == u(:,1)
    theta = real(acosd(cosTheta));

    if strcmp(resultFormat, 'deg')
        % already done
    elseif strcmp(resultFormat, 'rad')
        theta = deg2rad(theta);
    else
        error('unknown resultFormat');
    end
end