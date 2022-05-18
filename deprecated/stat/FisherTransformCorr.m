% deprecated
function [z] = FisherTransformCorr (r)
    z = 0.5 .* log((1+r) ./ (1-r)); %natural log is correct
end
