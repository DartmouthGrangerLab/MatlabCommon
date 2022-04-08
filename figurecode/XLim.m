% Eli Bowen 1/15/2021
% crash-proof version of xlim
% INPUTS:
%   lims
function [] = XLim(lims)
    try
        xlim(lims);
    end
end