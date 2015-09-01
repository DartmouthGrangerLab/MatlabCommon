%Input:
%   h - figure handle. If empty, will create one.
%   targetsWide - 
%   predWide - 
%   labels - text to display for each category
function [h] = PlotConfMat (h, targetsWide, predWide, labels)
    if isempty(h)
        h = figure();
    end
    set(h, 'Renderer', 'painters');
%     imagesc(confMat);
    plotconfusion(targetsWide, predWide);
    set(gca, 'YTickLabel', [labels;' ';' ']);
    set(gca, 'XTickLabel', [labels;' ';' ']);
    xticklabel_rotate([], 90, [], 'FontSize', 16);
%     colorbar;
    set(gca, 'FontSize', 12);
end