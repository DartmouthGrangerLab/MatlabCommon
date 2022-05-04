% Eli Bowen 1/21/2022
% like matlab's diary(), but overwrites any existing files
% don't forget to call "diary off"
% INPUTS:
%   path - (char) diary directory
%   file - (char) diary file name
function [] = Diary(path, file)
    validateattributes(path, {'char'}, {'nonempty'}, 1);
    validateattributes(file, {'char'}, {'nonempty'}, 2);
    assert(endsWith(file, '.txt'));

    if ~isfolder(path)
        mkpath(path);
    end

    if isfile(fullfile(path, file))
        delete(fullfile(path, file));
    end
    diary(fullfile(path, file));
end