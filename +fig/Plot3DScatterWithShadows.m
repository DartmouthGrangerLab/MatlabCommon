% Eli Bowen 11/4/2018
% plot a 3D scatter plot with shadows along each axis plane
% INPUTS
%   h          - OPTIONAL - handle to existing figure. If [], will create one
%   x          - 1 x n_points (numeric) coordinates: 1st param of matlab's scatter3()
%   y          - 1 x n_points (numeric) coordinates: 2nd param of matlab's scatter3()
%   z          - 1 x n_points (numeric) coordinates: 3rd param of matlab's scatter3()
%   s          - OPTIONAL - size: 4th param of matlab's scatter3()
%   c          - OPTIONAL - color: 5th param of matlab's scatter3()
%   markertype - OPTIONAL - param of matlab's scatter3()
%   xLimits    - OPTIONAL 1 x 2 (numeric) specify x axis limits (you can't change these later cuz the shadows are drawn on the axis mins)
%   yLimits    - OPTIONAL 1 x 2 (numeric) specify x axis limits (you can't change these later cuz the shadows are drawn on the axis mins)
%   zLimits    - OPTIONAL 1 x 2 (numeric) specify x axis limits (you can't change these later cuz the shadows are drawn on the axis mins)
%   drawGaussFitsOnShadows - OPTIONAL scalar (logical) if true, will draw gaussian fits on the shadows (default = false)
%   do_draw_drop_lines     - OPTIONAL scalar (logical) default = true for small numbers of points
%   do_only_shadows        - OPTIONAL scalar (logical) if true, only draw shadows not main points (default = false)
% RETURNS
%   h
%   scatterH
function [h,scatterH] = Plot3DScatterWithShadows(h, x, y, z, s, c, markertype, xLimits, yLimits, zLimits, drawGaussFitsOnShadows, do_draw_drop_lines, do_only_shadows)
    validateattributes(x, {'numeric'}, {'vector'}, 2);
    validateattributes(y, {'numeric'}, {'vector'}, 3);
    validateattributes(z, {'numeric'}, {'vector'}, 4);
    assert(numel(x) == numel(y) && numel(x) == numel(z));
    x = x(:); % scatter3 seems to like these vectors to be juuust right
    y = y(:); % scatter3 seems to like these vectors to be juuust right
    z = z(:); % scatter3 seems to like these vectors to be juuust right
    if isempty(h)
        h = figure();
    end
    if ~exist('s', 'var') || isempty(s)
        s = 36; % matlab default
    end
    if ~exist('c', 'var') || isempty(c)
        c = [0,0,1]; % matlab default
    end
    if ~exist('markertype', 'var') || isempty(markertype)
        markertype = 'o'; % matlab default
    end
    if ~exist('drawGaussFitsOnShadows', 'var') || isempty(drawGaussFitsOnShadows)
        drawGaussFitsOnShadows = false;
    end
    if ~exist('do_draw_drop_lines', 'var') || isempty(do_draw_drop_lines)
        do_draw_drop_lines = (numel(x) < 100);
    end
    if ~exist('do_only_shadows', 'var') || isempty(do_only_shadows)
        do_only_shadows = false;
    end
    gaussColor = [0.5,0.5,0.5];

    hold on % here we go!

    %% draw points
    scatterH = [];
    if ~do_only_shadows
        scatterH = scatter3(x, y, z, s, c, 'Marker', markertype, 'LineWidth', 1.0); % default LineWidth is 0.5
    end

    %% set axis limits
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
%     if size(c, 1) == numel(x) && size(c, 2) == 3 % if you specified a bunch of colors
%         if strcmp(markertype, 'none')
%             shadowColor = c; % shadows aren't behind real 3d points, so use high-contrast colors
%         elseif strcmp(gaussColor, 'w') || (isnumeric(gaussColor) && mean(gaussColor) > 0.5) % if we're rendering on black
%             shadowColor = c .* 0.5; % dimmer version of point color
%         else
%             shadowColor = 1 - ((1-c) .* 0.5); % whiter version of point color
%         end
%     else
%         shadowColor = [0.5,0.5,0.5];
%     end
    shadowColor = c;
    h = scatter3(xlims(1).*ones(size(x)), y, z, round(s*0.35), shadowColor, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.5);
    set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
    h = scatter3(x, ylims(1).*ones(size(y)), z, round(s*0.35), shadowColor, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.5);
    set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
    h = scatter3(x, y, zlims(1).*ones(size(z)), round(s*0.35), shadowColor, 'filled', 'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.5);
    set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
    if drawGaussFitsOnShadows
        sdWidth = 1;
        gaussLineWidth = 1;
        if size(c, 1) == numel(x) && size(c, 2) == 3 % if you specified a bunch of colors
            [~,~,labels] = unique(c, 'rows', 'stable');
            for i = 1 : numel(unique(labels))
                h = scatter3(xlims(1) + (xlims(2)-xlims(1))*0.01, mean(y(labels==i)), mean(z(labels==i)), round(s*0.35), gaussColor, 'filled', 'MarkerEdgeColor', 'none');
                set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
                h = scatter3(mean(x(labels==i)), ylims(1) + (ylims(2)-ylims(1))*0.01, mean(z(labels==i)), round(s*0.35), gaussColor, 'filled', 'MarkerEdgeColor', 'none');
                set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
                h = scatter3(mean(x(labels==i)), mean(y(labels==i)), zlims(1) + (zlims(2)-zlims(1))*0.01, round(s*0.35), gaussColor, 'filled', 'MarkerEdgeColor', 'none');
                set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
                PlotGausses(x(labels==i), y(labels==i), z(labels==i), xlims, ylims, zlims, sdWidth, gaussLineWidth, gaussColor);
            end
        else
            h = scatter3(xlims(1) + (xlims(2)-xlims(1))*0.01, mean(y), mean(z), round(s*0.35), gaussColor, 'filled', 'MarkerEdgeColor', 'none');
            set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
            h = scatter3(mean(x), ylims(1) + (ylims(2)-ylims(1))*0.01, mean(z), round(s*0.35), gaussColor, 'filled', 'MarkerEdgeColor', 'none');
            set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
            h = scatter3(mean(x), mean(y), zlims(1) + (zlims(2)-zlims(1))*0.01, round(s*0.35), gaussColor, 'filled', 'MarkerEdgeColor', 'none');
            set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
            PlotGausses(x, y, z, xlims, ylims, zlims, sdWidth, gaussLineWidth, gaussColor);
        end
    end

    %% draw lines down to bottom plane
    if do_draw_drop_lines
        for i = 1 : numel(x)
            h = plot3([x(i),x(i)], [y(i),y(i)], [zlims(1),z(i)], ':', 'Color', [0.5,0.5,0.5]);
            set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
        end
    end

    xlabel('X'); ylabel('Y'); zlabel('Z'); % you may wish to call these functions again to give more useful axis labels

    grid on
    box on
    view(135, 45);
end


function [] = PlotGausses(x, y, z, xlims, ylims, zlims, sdWidth, gaussLineWidth, color)
    % copied from plot_gaussian_ellipsoid
    n_pts = 50;
    tt = linspace(0, 2*pi, n_pts)';
    x2 = cos(tt);
    y2 = sin(tt);
    ap = [x2(:),y2(:)]';
    try
        GMModel = fitgmdist([y(:),z(:)], 1);
        [v,d] = eig(GMModel.Sigma);
        d = sdWidth * sqrt(d); % convert variance to sdwidth*sd
        bp = (v*d*ap) + repmat(GMModel.mu(:), 1, size(ap, 2)); 
        h = plot3(xlims(1).*ones(n_pts, 1) + (xlims(2)-xlims(1))*0.01, bp(1,:), bp(2,:), '-', 'Color', color, 'LineWidth', gaussLineWidth);
        set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
        
        GMModel = fitgmdist([x(:),z(:)], 1);
        [v,d] = eig(GMModel.Sigma);
        d = sdWidth * sqrt(d); % convert variance to sdwidth*sd
        bp = (v*d*ap) + repmat(GMModel.mu(:), 1, size(ap, 2)); 
        h = plot3(bp(1,:), ylims(1).*ones(n_pts, 1) + (ylims(2)-ylims(1))*0.01, bp(2,:), '-', 'Color', color, 'LineWidth', gaussLineWidth);
        set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
        
        GMModel = fitgmdist([x(:),y(:)], 1);
        [v,d] = eig(GMModel.Sigma);
        d = sdWidth * sqrt(d); % convert variance to sdwidth*sd
        bp = (v*d*ap) + repmat(GMModel.mu(:), 1, size(ap, 2)); 
        h = plot3(bp(1,:), bp(2,:), zlims(1).*ones(n_pts, 1) + (zlims(2)-zlims(1))*0.01, '-', 'Color', color, 'LineWidth', gaussLineWidth); % default linewidth=0.5
        set(get(get(h, 'Annotation'), 'LegendInformation'), 'IconDisplayStyle', 'off'); % omit from legends
    end
end