% Eli Bowen 1/21/2022
% like matlab's diary(), but overwrites any existing files
% don't forget to call "diary off"
% INPUTS:
%   dir
%   file
function [] = Diary(dir, file)
    validateattributes(dir,  {'char'}, {'nonempty'}, 1);
    validateattributes(file, {'char'}, {'nonempty'}, 2);
    assert(endsWith(file, '.txt'));

    mkdir(dir);
    if isfile(fullfile(dir, file))
        delete(fullfile(dir, file));
    end
    diary(fullfile(dir, file));
end