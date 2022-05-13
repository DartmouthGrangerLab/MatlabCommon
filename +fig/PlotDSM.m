% from http://stackoverflow.com/questions/3942892/how-do-i-visualize-a-matrix-with-colors-and-values-displayed
% modified by Eli Bowen 1/2016
% INPUTS:
%   h         - figure handle. If empty, will create one.
%   mat       - YxX matrix
%   xLabels   - (OPTIONAL) text to display for each category along the X axis (cell array of strings)
%   yLabels   - (OPTIONAL) text to display for each category along the Y axis (cell array of strings)
%   precision - (OPTIONAL) number of decimal points to render. default = 4.
%   fontSize  - (OPTIONAL) font size for the text. Can leave blank for matlab defaults of 10.
%   unit      - (OPTIONAL) a string containing the units of the values in mat (will be printed inside the cells)
% EFWB 4/26/2018: changing so doesn't need to be a square matrix. big change is instead of one param "labels" we now have 2: "xLabels" and "yLabels"
function h = PlotDSM(h, mat, xLabels, yLabels, precision, fontSize, unit)
    if exist('xLabels', 'var') && ~isempty(xLabels)
        assert(numel(xLabels) == size(mat, 2));
    end
    if exist('yLabels', 'var') && ~isempty(yLabels)
        assert(numel(yLabels) == size(mat, 1));
    end
    if ~exist('precision', 'var') || isempty(precision)
        precision = 4;
    end
    if ~exist('fontSize', 'var') || isempty(fontSize)
        fontSize = 10; % this is the matlab default
    end

    if isempty(h)
        h = figure();
    end
    set(h, 'Renderer', 'painters');

    %% print matrix
    imagesc(mat); % create a colored plot of the matrix values
    colormap(flipud(gray)); % change the colormap to gray (so higher values are black and lower values are white)
	axis(gca, 'equal');

    %% print numbers inside cells
    if size(mat, 1) < 20 && size(mat, 2) < 20
        textStrings = num2str(mat(:), ['%0.',num2str(precision),'f']); % create strings from the matrix values
        textStrings = strtrim(cellstr(textStrings)); % remove any space padding
        if exist('unit', 'var') && ~isempty(unit)
            assert(ischar(unit));
            for i = 1:numel(textStrings) % linear indexing
                textStrings{i} = [textStrings{i},unit];
            end
        end
        [x,y] = meshgrid(1:size(mat, 2), 1:size(mat, 1)); % create x and y coordinates for the strings (yes the dimensions seem reversed)
        hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center', 'FontSize', fontSize); % plot the strings (font size 10 = default)
        midValue = mean(get(gca,'CLim')); % get the middle value of the color range
        textColors = repmat(mat(:) > midValue, 1, 3); % choose white or black for the text color of the strings so
                                                      % they can be easily seen over the background color
        set(hStrings, {'Color'}, num2cell(textColors, 2)); % change the text colors
    else
        colorbar;
    end

    %% print text labels
%     set(gca, 'XTick', 1:size(mat, 2), ...  % change the axes tick marks
%             'XTickLabel', xLabels, ...      % and tick labels
%             'YTick', 1:size(mat, 1), ...
%             'YTickLabel', yLabels, ...
%             'TickLength', [0 0]);
    ax = gca();
    if exist('xLabels', 'var') && ~isempty(xLabels)
        ax.XTick = 1:size(mat, 2);
        ax.XTickLabel = xLabels;
    elseif size(mat, 2) < 20
        ax.XTick = 1:size(mat, 2); % change the axes tick marks
    else
        ax.XTick = 10:10:size(mat, 2); % change the axes tick marks
    end
    if exist('yLabels', 'var') && ~isempty(yLabels)
        ax.YTick = 1:size(mat, 1);
        ax.YTickLabel = yLabels;
    elseif size(mat, 1) < 20
        ax.YTick = 1:size(mat, 1); % change the axes tick marks
    else
        ax.YTick = 10:10:size(mat, 2); % change the axes tick marks
    end
    ax.TickLength = [0,0];
    ax.FontSize = fontSize; % default = 10
end
