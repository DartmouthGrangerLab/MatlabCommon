% Eli Bowen 1/15/2021
% crash-proof version of ylim
% INPUTS
%   lims
% see also ylim
function [] = ylim(lims)
    try
        ylim(lims);
    end
end