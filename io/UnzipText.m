% Eli Bowen
% 1/20/2022
% extracts a zip file, loads the text file within, then deletes the extracted copy
% MUST be a SINGLE text file in the zip (any file extension)
% great for loading compressed text datasets
% INPUTS:
%   fileName - char - name of zip file
% RETURNS
%   text
function [text] = UnzipText(fileName)
    validateattributes(fileName, 'char', {'nonempty'});
    assert(endsWith(fileName, '.zip'));

    [~,rawFileName,~] = fileparts(fileName);
    rawFileName = strrep(rawFileName, '.', '_');
    directory = fullfile(ComputerProfile.CacheDir(), ['unziptext_',rawFileName]);
    assert(~isfolder(directory));

    fileNames = unzip(fileName, directory);
    assert(numel(fileNames) == 1);

    text = fileread(fileNames{1});

    delete(fullfile(directory, '*'));
    rmdir(directory);
end