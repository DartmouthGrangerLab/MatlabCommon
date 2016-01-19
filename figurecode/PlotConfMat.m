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
    plotconfusion(targetsWide, predWide);
    if size(labels,1) < size(labels,2)
        labels = labels';
    end
    set(gca, 'YTickLabel', [labels;' ';' ']);
    set(gca, 'XTickLabel', [labels;' ';' ']);
    xticklabel_rotate([], 90, [], 'FontSize', 16);
%     colorbar;
    set(gca, 'FontSize', 12);
end