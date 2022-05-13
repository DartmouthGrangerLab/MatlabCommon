% Eli Bowen 4/2022
% thanks some rando on stackexchange
% INPUTS
%   data   - d x n_plots (numeric or logical)
%   mode   - (char) 'density' or 'hist'
%   n_bins - OPTIONAL scalar (int-valued numeric) num histogram bins
% RETURNS
%   x
%   y
function [x,y] = PDF(data, mode, n_bins)
    validateattributes(data, {'numeric','logical'}, {}, 1);
    validateattributes(mode, {'char'}, {'nonempty'}, 2);
    if isvector(data)
        data = data(:);
    end
    n_plots = size(data, 2);
    if ~exist('n_bins', 'var') || isempty(n_bins)
        n_bins = 100;
    end
    if isempty(data)
        x = [];
        y = [];
        return
    end

    binLim = [min(data(:)),max(data(:))];
    assert(binLim(1) ~= binLim(2)); % data must take >1 value

    if strcmp(mode, 'density')
        x = binLim(1):(binLim(2)-binLim(1))/n_bins:binLim(2);
        y = zeros(numel(x), n_plots);
        if ~isa(data, 'float')
            data = double(data);
        end
        for i = 1 : n_plots
            y(:,i) = ksdensity(data(:,i), x);
        end
    elseif strcmp(mode, 'hist')
        y = zeros(n_bins, n_plots);
        [y(:,1),x] = histcounts(data(:,1), n_bins, 'Normalization', 'pdf', 'BinLimits', binLim);
        x = x(2:end) - (x(2)-x(1))/2;
        for i = 2 : n_plots
            y(:,i) = histcounts(data(:,i), n_bins, 'Normalization', 'pdf', 'BinLimits', binLim);
        end
    else
        error('unexpected mode');
    end
end