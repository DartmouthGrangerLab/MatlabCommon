% Eli Bowen 8/17/2020
% INPUTS
%   pos1       - 1 x 2 (numeric)
%   pos2       - 1 x 2 (numeric)
%   poly1      - scalar (int-valued numeric)
%   poly2      - scalar (int-valued numeric)
%   polyRadius - scalar (numeric)
%   puckerFactor - OPTIONAL (default = 1 aka none) scalar (numeric) squeeze radius this much in one direction
% RETURNS
%   result
function result = PolygonsOverlap(pos1, pos2, poly1, poly2, polyRadius, puckerFactor)
    validateattributes(pos1,       {'numeric'}, {'nonempty','vector'}, 1);
    validateattributes(pos2,       {'numeric'}, {'nonempty','vector'}, 2);
    validateattributes(poly1,      {'numeric'}, {'nonempty','scalar','positive','integer'}, 3);
    validateattributes(poly2,      {'numeric'}, {'nonempty','scalar','positive','integer'}, 4);
    validateattributes(polyRadius, {'numeric'}, {'nonempty','scalar','positive'}, 5);
    if ~exist('puckerFactor', 'var') || isempty(puckerFactor)
        puckerFactor = 1; % squeeze radius this much in one direction
    end

    pointSet = geom.PolygonPointSet(polyRadius, puckerFactor);
    result = any(inpolygon(...
                    pos1(1) + pointSet{poly1}(1,:),...
                    pos1(2) + pointSet{poly1}(2,:),...
                    pos2(1) + pointSet{poly2}(1,:),...
                    pos2(2) + pointSet{poly2}(2,:)));
    result = result || any(inpolygon(...
                    pos2(1) + pointSet{poly2}(1,:),...
                    pos2(2) + pointSet{poly2}(2,:),...
                    pos1(1) + pointSet{poly1}(1,:),...
                    pos1(2) + pointSet{poly1}(2,:)));
end