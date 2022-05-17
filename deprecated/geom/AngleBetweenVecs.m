% deprecated
function theta = AngleBetweenVecs(u, v, resultFormat)
    validateattributes(u, {'numeric'}, {'nonempty','matrix'}, 1);
    validateattributes(v, {'numeric'}, {'nonempty','matrix'}, 2);
    validateattributes(resultFormat, {'char'}, {'nonempty'}, 3);

    cosTheta = max(min(dot(u, v) ./ (vecnorm(u).*vecnorm(v)), 1), -1);
    theta = real(acosd(cosTheta));

    if strcmp(resultFormat, 'deg')
        % already done
    elseif strcmp(resultFormat, 'rad')
        theta = deg2rad(theta);
    else
        error('unknown resultFormat');
    end
end