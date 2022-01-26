% Eli Bowen
% 1/21/2022
% like matlab's diary(), but overwrites any existing files
% don't forget to call "diary off"
% INPUTS:
%   dir
%   file
function [] = Diary(dir, file)
    validateattributes(dir,  'char', {'nonempty'});
    validateattributes(file, 'char', {'nonempty'});
    assert(endsWith(file, '.txt'));

    mkdir(dir);
    delete(fullfile(dir, file));
    diary(fullfile(dir, file));
end