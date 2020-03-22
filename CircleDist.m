%Eli Bowen
%2/24/2020
%distance around the edge of a circle, in degrees
%INPUTS:
%   a - first angle in degrees
%   b - second angle in degrees
%   units - 'deg' or 'rad' (what are the units of a and b?
function [dist] = CircleDist (a, b, units)
    if strcmp(units, 'rad')
        a = a .* (180 / pi); %convert to degrees
        b = b .* (180 / pi); %convert to degrees
    else
        assert(strcmp(units, 'deg'));
    end
    
    dist = abs(a - b); %dist around the circle in one direction
    dist(dist > 180) = 360 - dist(dist > 180); %dist around the circle in the other direction
end