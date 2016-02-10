%from http://stackoverflow.com/questions/3942892/how-do-i-visualize-a-matrix-with-colors-and-values-displayed
%modified by Eli Bowen 1/2016
%INPUTS:
%   h - figure handle. If empty, will create one.
%   mat - 
%   labels - text to display for each category (cell array of strings)
%   precision - (OPTIONAL) number of decimal points to render. default = 4.
function [h] = PlotDSM (h, mat, labels, precision)
    assert(size(mat, 1) == size(mat, 2), 'mat must be a square matrix!');
    if isempty(precision)
        precision = 4;
    end
    
    if isempty(h)
        h = figure();
    end
    set(h, 'Renderer', 'painters');
    imagesc(mat); %create a colored plot of the matrix values
    colormap(flipud(gray)); %change the colormap to gray (so higher values are black and lower values are white)

    if numel(labels) < 20
        textStrings = num2str(mat(:), ['%0.',num2str(precision),'f']); %create strings from the matrix values
        textStrings = strtrim(cellstr(textStrings)); %remove any space padding
        [x,y] = meshgrid(1:size(mat, 1)); %create x and y coordinates for the strings
        hStrings = text(x(:), y(:), textStrings(:), 'HorizontalAlignment', 'center'); %plot the strings
        midValue = mean(get(gca,'CLim')); %get the middle value of the color range
        textColors = repmat(mat(:) > midValue, 1, 3); %choose white or black for the text color of the strings so
                                                      %they can be easily seen over the background color
        set(hStrings, {'Color'}, num2cell(textColors, 2)); %change the text colors
    end

    set(gca, 'XTick', 1:size(mat, 1), ...  %change the axes tick marks
            'XTickLabel', labels, ...      %and tick labels
            'YTick', 1:size(mat, 1), ...
            'YTickLabel', labels, ...
            'TickLength', [0 0]);
end