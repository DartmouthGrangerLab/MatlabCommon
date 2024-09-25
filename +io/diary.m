% Eli Bowen 1/21/2022
% like matlab's diary(), but overwrites any existing files
% don't forget to call "diary off"
% INPUTS
%   path - (char) diary directory
%   file - (char) diary file name
function [] = diary(path, file)
    if isMATLABReleaseOlderThan("R2016b") % MatlabCommon must support versions prior to the creation of strings
        validateattributes(path, {'char'}, {'nonempty'}, 1);
        validateattributes(file, {'char'}, {'nonempty'}, 2);
    else
        validateattributes(path, {'char','string'}, {'nonempty'}, 1);
        validateattributes(file, {'char','string'}, {'nonempty'}, 2);
    end
    
    assert(endsWith(file, '.txt'));

    if ~isfolder(path)
        mkdir(path);
    end

    if isfile(fullfile(path, file))
        delete(fullfile(path, file));
    end
    diary(fullfile(path, file));
end