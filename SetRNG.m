%Eli Bowen
%4/16/2020
%INPUTS:
%   data2Hash - hash of this data will generate the seed (if a scalar numeric int, we will use this as the seed)
function [] = SetRNG (data2Hash)
    if isnumeric(data2Hash) && numel(data2Hash) == 1 && mod(data2Hash, 1) == 0
        seed = data2Hash;
    else
        hash = GetMD5(data2Hash, 'array', 'hex');
        seed = hex2dec(hash(1:7)); % using 7 of the 32 chars in the MD5 hex as a seed - repeatable results
    end
    rng('default'); % crashes may result if you don't call this before the next line
    rng(seed, 'simdTwister');
    gpurng(seed, 'Threefry'); % threefry is default, but let's keep it predictable in future matlab versions
    
    disp(['RNG initialized to seed = ',num2str(seed)]);
end