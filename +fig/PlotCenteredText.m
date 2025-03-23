% Eli Bowen 4/2022
% INPUTS
%   str - (char|string) text to plot
%   color - (char|string) OPTIONAL color to pass to matlab's text()
function [] = PlotCenteredText(str, color)
    if ~exist('color', 'var')
        color = 'k';
    end
    ax = gca();
    text(ax.YLim(1)/2, ax.YLim(2)/2, str, 'HorizontalAlignment', 'center', 'Color', color);
end