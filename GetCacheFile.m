% Eli Bowen
% 6/9/2020
% gets the path of a cache file, given some data to hash and any text you wish to append to the filename
% just a little helper function for convenience and consistency
% INPUTS:
%   data2Hash
%   append
function [cacheFile] = GetCacheFile (data2Hash, append)
    validateattributes(append, {'char'}, {'nonempty','vector'});
    
    profile = ComputerProfile();
    hash = GetMD5(data2Hash, 'array', 'hex');
    cacheFile = fullfile(profile.cache_dir, [append,'_hash',hash,'.mat']);
end