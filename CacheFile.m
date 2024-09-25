% Eli Bowen 6/9/2020
% gets the path of a cache file, given some data to hash and any text you wish to append to the filename
% just a little helper function for convenience and consistency
% INPUTS:
%   data2Hash - any data to hash; beware custom classes
%   append    - char to append to file name
%   subDir    - OPTIONAL char, sub-directory within the cache dir to use
% RETURNS:
%   file - char - mat file name with path
function file = CacheFile(data2Hash, append, subDir)
    if isMATLABReleaseOlderThan("R2016b") % MatlabCommon must support versions prior to the creation of strings
        validateattributes(append, {'char'}, {'nonempty','vector'}, 2);
    else
        validateattributes(append, {'char','string'}, {'nonempty'}, 2);
    end
    
    hash = '';
    if ~isempty(data2Hash)
        try
            hash = GetMD5(data2Hash, 'array', 'hex');
        catch
            hash = GetMD5(getByteStreamFromArray(data2Hash), 'array', 'hex');
        end
        hash = ['_hash',hash];
    end

    dir = ComputerProfile.CacheDir();
    if exist('subDir', 'var') && ~isempty(subDir)
        dir = fullfile(dir, subDir);
    end

    file = fullfile(dir, [char(append),hash,'.mat']);

    if ~isfolder(dir)
        mkdir(dir);
    end
end