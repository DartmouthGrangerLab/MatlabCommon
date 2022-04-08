% Eli Bowen 4/2022
% thanks some rando on stackexchange
% INPUTS:
%   data   - d x n_plots (numeric or logical)
%   n_bins - scalar (int-valued numeric) num histogram bins, 'auto' for automatic (slower, involves interpolation)
%   other inputs to Plot
% RETURNS:
%   h - handle to plot
% see also Plot
function h = PlotPDF(data, n_bins, varargin)
    validateattributes(data, {'numeric','logical'}, {}, 1);
    validateattributes(n_bins, {'numeric','char'}, {'nonempty'}, 2);
    if isvector(data)
        data = data(:);
    end
    data = double(data);
    n_plots = size(data, 2);

    binLim = [min(data(:)),max(data(:))];

    if strcmp(n_bins, 'auto')
        if binLim(2) - binLim(1) >= 1
            x = binLim(1):binLim(2);
        else
            x = binLim(1):(binLim(2)-binLim(1))/100:binLim(2);
        end
        edges  = zeros(numel(x), n_plots);
        counts = zeros(numel(x), n_plots);
        for i = 1 : n_plots
            [tempCounts,temp] = histcounts(data(:,i), 'Normalization', 'pdf', 'BinLimits', binLim);
            temp = temp(2:end) - (temp(2)-temp(1))/2;
            edges(:,i) = x;
            counts(:,i) = spline(temp, tempCounts, x);
        end
    else
        edges  = zeros(n_bins, n_plots);
        counts = zeros(n_bins, n_plots);
        for i = 1 : n_plots
            [counts(:,i),temp] = histcounts(data(:,i), n_bins, 'Normalization', 'pdf', 'BinLimits', binLim);
            edges(:,i) = temp(2:end) - (temp(2)-temp(1))/2;
        end
    end

    h = Plot(edges, counts, varargin{:});

    ylabel('pdf');
end