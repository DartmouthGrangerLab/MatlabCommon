% Eli Bowen
% 1/2017
function [nCores] = DetermineNumJavaComputeCores ()
    nCores = feature('numCores');
    if nCores == 24
%         if contains(NameOfComputer(), 'boskop')
%             numCores = 48; % otherwise it's a J node
%         end
    elseif nCores ~= 16 % 16 is the response of most worker nodes
        if strcmp(NameOfComputer(), 'eb-grangerlab')
            nCores = 4; % so I can still use the computer
        end
    end
end