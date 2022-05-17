% deprecated
function [r,c] = FindCircleCoords(count)
    validateattributes(count, {'numeric'}, {'nonempty','scalar'}, 1);

    centerR = 0.5;
    centerC = 0.5;
    radius = 0.5;

    th = 0:pi/(0.5*count):2*pi;
    th(end) = [];
    r = radius * cos(th) + centerR;
    c = radius * sin(th) + centerC;
end