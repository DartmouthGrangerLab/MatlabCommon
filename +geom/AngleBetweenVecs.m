% Eli Bowen 12/19/2020
% angle between two vectors
% based on a mathworks employee's web post: https://www.mathworks.com/matlabcentral/answers/101590-how-can-i-determine-the-angle-between-two-vectors-in-matlab
% if you want the angle between two connected lines (connected at point2): theta = AngleBetweenVecs(point1 - point2, point3 - point2, resultFormat)
% this is the minimum angle, so return values will always be in the range 0-->180 deg (or equivalent rads)
% INPUTS
%   u            - (numeric) a vector, or collection of vectors where each column is a single vector
%   v            - (numeric) a vector, or collection of vectors where each column is a single vector
%   resultFormat - (char) 'deg' or 'rad'
% RETURNS
%   theta
% see also AngleOfVec2D
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