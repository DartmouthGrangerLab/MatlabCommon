% Eli Bowen
% 1/15/2021
% crash-proof version of ylim
function [] = YLim(lims)
    try
        ylim(lims);
    end
end