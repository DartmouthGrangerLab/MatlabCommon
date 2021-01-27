%Eli Bowen
%12/20/2020
%counts number of digits in the input
%return value will be same size and datatype as data
%more efficient if you pass a floating point datatype
%https://www.mathworks.com/matlabcentral/answers/10795-counting-the-number-of-digits
%INPUTS:
%   data - numeric of any datatype but integer-valued
function [data] = NumDigits (data)
    validateattributes(data, {'numeric'}, {'integer'});
    
    isInt = false;
    if isinteger(data)
        isInt = true;
        dataClass = class(data);
        data = double(data);
    end
    
    isZero = (data == 0);
    data = fix(abs(log10(abs(data(~isZero))))) + 1;
    data(isZero) = 1; % otherwise will return Inf
    
    if isInt
        data = cast(data, dataClass);
    end
end