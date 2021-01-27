%Eli Bowen
%12/19/2020
% returns a rotation matrix (if 3D, performs rotations in order x, y, z)
%INPUTS:
%   rVec - a 2D or 3D rotation formatted as [r] or [rX,rY,rZ]
%   angleFormat - 'deg' or 'rad' (is rVec in units of degrees or radians?)
function [rotationMat] = RotationMat (rVec, angleFormat)
    validateattributes(rVec, {'numeric'}, {'nonempty','vector'});
    validateattributes(angleFormat, {'char'}, {'nonempty'});

    if numel(rVec) == 1
        if strcmp(angleFormat, 'deg')
            rotationMat = [cosd(r),-sind(r);...
                           sind(r),cosd(r)];
        elseif strcmp(angleFormat, 'rad')
            rotationMat = [cos(r),-sin(r);...
                           sin(r),cos(r)];
        else
            error('unknown input angleFormat');
        end
    elseif numel(rVec) == 3
        if strcmp(angleFormat, 'deg')
            rxMat = [1,0,0;...
                     0,cosd(rVec(1)),-sind(rVec(1));...
                     0,sind(rVec(1)),cosd(rVec(1))];
            ryMat = [cosd(rVec(2)),0,sind(rVec(2));...
                     0,1,0;...
                     -sind(rVec(2)),0,cosd(rVec(2))];
            rzMat = [cosd(rVec(3)),-sind(rVec(3)),0;...
                     sind(rVec(3)),cosd(rVec(3)),0;...
                     0,0,1];
        elseif strcmp(angleFormat, 'rad')
            rxMat = [1,0,0;...
                     0,cos(rVec(1)),-sin(rVec(1));...
                     0,sin(rVec(1)),cos(rVec(1))];
            ryMat = [cos(rVec(2)),0,sin(rVec(2));...
                     0,1,0;...
                     -sin(rVec(2)),0,cos(rVec(2))];
            rzMat = [cos(rVec(3)),-sin(rVec(3)),0;...
                     sin(rVec(3)),cos(rVec(3)),0;...
                     0,0,1];
        else
            error('unknown input angleFormat');
        end
        
        rotationMat = rxMat * ryMat * rzMat;
    else
        error('rVec must be 2D (1 angle) or 3D (3 angles)');
    end
end