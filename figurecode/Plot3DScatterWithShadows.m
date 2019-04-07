%Eli Bowen
%11/4/2018
%Plot a 3D scatter plot with shadows along each axis plane
%INPUTS:
%   h - OPTIONAL - handle to existing figure. If [], will create one
%   x - coordinates: 1st param of matlab's scatter3()
%   y - coordinates: 2nd param of matlab's scatter3()
%   z - coordinates: 3rd param of matlab's scatter3()
%   s - OPTIONAL - size: 4th param of matlab's scatter3()
%   c - OPTIONAL - color: 5th param of matlab's scatter3()
%   markertype - OPTIONAL - param of matlab's scatter3()
%   xLimits - OPTIONAL - specify x axis limits (you can't change these later cuz the shadows are drawn on the axis mins)
%   yLimits - OPTIONAL - specify x axis limits (you can't change these later cuz the shadows are drawn on the axis mins)
%   zLimits - OPTIONAL - specify x axis limits (you can't change these later cuz the shadows are drawn on the axis mins)
function [h,scatterH] = Plot3DScatterWithShadows (h, x, y, z, s, c, markertype, xLimits, yLimits, zLimits)
    validateattributes(x, {'numeric'}, {'vector'}, 'Plot3DScatterWithShadows', 'x', 2);
    validateattributes(y, {'numeric'}, {'vector'}, 'Plot3DScatterWithShadows', 'y', 3);
    validateattributes(z, {'numeric'}, {'vector'}, 'Plot3DScatterWithShadows', 'z', 4);
    assert(numel(x) == numel(y) && numel(x) == numel(z));
    x = x(:); %scatter3 seems to like these vectors to be juuust right
    y = y(:); %scatter3 seems to like these vectors to be juuust right
    z = z(:); %scatter3 seems to like these vectors to be juuust right
    if isempty(h)
        h = figure();
    end
    if ~exist('s', 'var') || isempty(s)
        s = 36; %matlab default
    end
    if ~exist('c', 'var') || isempty(c)
        c = [0,0,1]; %matlab default
    end
    if ~exist('markertype', 'var') || isempty(markertype)
        markertype = 'o'; %matlab default
    end
    
    hold on;
    %% draw points
    scatterH = scatter3(x, y, z, s, c, 'Marker', markertype, 'LineWidth', 1.0); %default LineWidth is 0.5
    if exist('xLimits', 'var') && ~isempty(xLimits)
        assert(isnumeric(xLimits) && numel(xLimits) == 2);
        xlim(xLimits);
    end
    if exist('yLimits', 'var') && ~isempty(yLimits)
        assert(isnumeric(yLimits) && numel(yLimits) == 2);
        ylim(yLimits);
    end
    if exist('zLimits', 'var') && ~isempty(zLimits)
        assert(isnumeric(zLimits) && numel(zLimits) == 2);
        zlim(zLimits);
    end
    
    %% draw shadows
    xlims = xlim();
    ylims = ylim();
    zlims = zlim();
    if size(c, 1) == numel(x) && size(c, 2) == 3 %if you specified a bunch of colors
        if strcmp(markertype, 'none')
            shadowColor = c; %shadows aren't behind real 3d points, so use high-contrast colors
        else
            shadowColor = 1 - ((1-c) * 0.5);
        end
    else
        shadowColor = [0.5,0.5,0.5];
    end
    scatter3(xlims(1)*ones(size(x)), y, z, round(s*0.35), shadowColor, 'filled', 'MarkerEdgeColor', 'none');
    scatter3(x, ylims(1)*ones(size(y)), z, round(s*0.35), shadowColor, 'filled', 'MarkerEdgeColor', 'none');
    scatter3(x, y, zlims(1)*ones(size(z)), round(s*0.35), shadowColor, 'filled', 'MarkerEdgeColor', 'none');
    
    %% draw lines down to bottom plane
    if numel(x) < 100
        for i = 1:numel(x)
            plot3([x(i),x(i)], [y(i),y(i)], [zlims(1),z(i)], ':', 'Color', [0.5,0.5,0.5]);
        end
    end
    
    xlabel('X'); ylabel('Y'); zlabel('Z'); %you may wish to call these functions again to give more useful axis labels
    
    grid on;
    box on;
    view(135, 45);
end