% Eli Bowen 3/2022
% angle between a vector and the vector [1,0]
% based on a mathworks employee's web post: https://www.mathworks.com/matlabcentral/answers/101590-how-can-i-determine-the-angle-between-two-vectors-in-matlab
% this is the minimum angle, so return values will always be in the range 0-->180 deg (or equivalent rads)
% INPUTS:
%   u            - 2 x n_vecs (numeric) a vector, or collection of vectors where each column is a single vector
%   resultFormat - (char) 'deg' or 'rad'
% RETURNS:
%   theta
% see also AngleBetweenVecs
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