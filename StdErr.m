function [stdErr] = StdErr (data)
    stdErr = std(data, 0, 1) / sqrt(length(data));
end