% deprecated
function [r] = FisherTransformCorrInverse (z)
    r = (exp(2.*z) - 1) ./ (exp(2.*z) + 1); %natural exponent is correct, exp(x) = e^x
end
