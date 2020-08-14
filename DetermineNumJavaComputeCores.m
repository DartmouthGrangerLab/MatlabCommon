%Eli Bowen
%1/2017
function [numCores] = DetermineNumJavaComputeCores ()
    numCores = feature('numCores');
    if numCores == 24
%         if contains(getComputerName(), 'boskop')
%             numCores = 48; %otherwise it's a J node
%         end
    elseif numCores ~= 16 %16 is the response of most worker nodes
        if strcmp(getComputerName(), 'eb-grangerlab')
            numCores = 4; %so I can still use the computer
        end
    end
end