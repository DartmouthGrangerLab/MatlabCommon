% Eli Bowen
% 10/1/2021
% sets the figure to be black background (safer and more extensible than the old matlab built-in way)
% call it AFTER rendering your data
% INPUTS:
%   h - OPTIONAL figure handle - default = gcf()
function [] = FigureSetBlackBackground(h)
    if ~exist('h', 'var') || isempty(h)
        h = gcf();
    end

    h.Color = [0.25,0.25,0.25]; % figure background (outside any plot)

    axes = findall(h, 'type', 'axes');
    for i = 1 : numel(axes)
        axes(i).Color     = [0,0,0];
        axes(i).XColor    = [1,1,1]; % x axis ticks and labels
        axes(i).YColor    = [1,1,1]; % y axis ticks and labels
        axes(i).GridColor = [1,1,1]; % has transparency by default, so won't look white (has no effect if your grid is off)
    end

    legends = findobj(h, 'Type', 'Legend');
    for i = 1 : numel(legends)
        legends(i).Color     = [0.1,0.1,0.1];
        legends(i).TextColor = [1,1,1];
        legends(i).EdgeColor = [0.85,0.85,0.85]; % inverse of matlab's white default (0.15)
        set(legends(i).BoxFace, 'ColorType', 'truecoloralpha', 'ColorData', uint8(255*[.1;.1;.1;.8])); % https://undocumentedmatlab.com/matlab/wp-content/cache/all/articles/transparent-legend/index.html
    end

    set(h, 'InvertHardCopy', 'off'); % when figure is saved to image file, keep this black background
end