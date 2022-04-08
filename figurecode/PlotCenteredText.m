% Eli Bowen 4/2022
% INPUTS:
%   str
function [] = PlotCenteredText(str)
    ax = gca();
    text(ax.YLim(1)/2, ax.YLim(2)/2, str, 'HorizontalAlignment', 'center');
end