% Eli Bowen
% INPUTS:
%   h - figure handle. If empty, will create one.
%   targets - 
%   pred - 
%   labels - OPTIONAL - 1 x nCategories (cell of chars) - text to display for each category
% RETURNS:
%   h - figure handle
function [h] = PlotROC (h, targets, pred, labels)
    validateattributes(targets, 'numeric', {'nonempty'});
    validateattributes(pred, 'numeric', {'nonempty'});
    if isvector(targets)
        assert(isvector(pred) && all(targets == 0 | targets == 1));
        targets = targets(:)';
        pred = pred(:)';
    else
        assert(all(size(targets) == size(pred)));
    end

    if isempty(h)
        h = figure();
    end

    markers = ['o','+','*','.','x','s','d','^','v','p','h'];
    set(h, 'Renderer', 'painters');
    plot([0,1], [0,1], 'Color', [0.5,0.5,0.5]);
    hold on;
%     plotroc(targets{i}, pred{i});
    [tpr,fpr,~] = roc(targets, pred);
    if isvector(targets) % 2-category case
        scatter([fpr,1], [tpr,1], [], lines(1), 'Marker', markers(2));
    else % multi-category case
        figColors = lines(1+numel(labels));
        for i = 1:numel(labels)
            scatter([fpr(i),1], [tpr(i),1], [], figColors(i,:), 'Marker', markers(1+mod(i,numel(markers))));
            hold on;
        end
        legend(labels);
    end
    set(gca, 'FontSize', 14);
    xlabel('FP Rate');
    ylabel('TP Rate');
	axis(gca, 'equal');
end