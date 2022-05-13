% Eli Bowen 1/15/2021
% crash-proof version of xlim
% INPUTS:
%   lims
% see also xlim
function [] = xlim(lims)
    try
        xlim(lims);
    end
end