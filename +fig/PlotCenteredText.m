% Eli Bowen 4/2022
% INPUTS
%   str - (char|string) text to plot
function [] = PlotCenteredText(str)
    ax = gca();
    text(ax.YLim(1)/2, ax.YLim(2)/2, str, 'HorizontalAlignment', 'center');
end