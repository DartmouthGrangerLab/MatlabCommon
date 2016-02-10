%Inputs:
%   data - vector of data points to test
function [stdErr] = StdErr (data)
    if sum(size(data)>1) > 1 %just to be clear
        stdErr = std(data, 0, 1) / sqrt(size(data, 1));
    else
        stdErr = std(data, 0) / sqrt(length(data));
    end
end