%Input:
%   h - figure handle. If empty, will create one.
%   targetsWide - 
%   predWide - 
%   labels - text to display for each category
function [h] = PlotROC (h, targetsWide, predWide, labels)
    if isempty(h)
        h = figure();
    end
    markerTypes = ['o','+','*','.','x','s','d','^','v','p','h'];
    figColors = lines(1+numel(labels));
    set(h, 'Renderer', 'painters');
%     plotroc(targetsWide{i}, predWide{i});
    [tpr,fpr,~] = roc(targetsWide, predWide);
    plot([0,1], [0,1], 'Color', [0.5,0.5,0.5]);
    hold on;
    for i = 1:numel(labels)
        scatter([fpr{i},1], [tpr{i},1], [], figColors(i,:), 'Marker', markerTypes(1+mod(i,numel(markerTypes))));
        hold on;
    end
    set(gca, 'FontSize', 14);
    legend(labels);
    xlabel('FP Rate');
    ylabel('TP Rate');
	axis(gca, 'equal');
end