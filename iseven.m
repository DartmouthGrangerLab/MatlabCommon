% based on code created by David Coventry, 8/2/2017
function [tf] = iseven (x)
    tf = (mod(x, 2) == 0);
end