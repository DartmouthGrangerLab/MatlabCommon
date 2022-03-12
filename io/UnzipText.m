% Eli Bowen 1/20/2022
% extracts a zip file, loads the text file within, then deletes the extracted copy
% MUST be a SINGLE text file in the zip (any file extension)
% great for loading compressed text datasets
% INPUTS:
%   fileName - (char) name of zip file
%   func     - OPTIONAL (char or function_handle) function to call to read the data (default = fileread)
% RETURNS
%   text
function [text] = UnzipText(fileName, func)
    validateattributes(fileName, 'char', {'nonempty'});
    assert(endsWith(fileName, '.zip'));
    if ~exist('func', 'var') || isempty(func)
        func = @fileread;
    end
    if ~isa(func, 'function_handle')
        func = str2func(func);
    end

    [~,rawFileName,~] = fileparts(fileName);
    rawFileName = strrep(rawFileName, '.', '_');
    directory = fullfile(ComputerProfile.CacheDir(), ['unziptext_',rawFileName]);
    assert(~isfolder(directory));

    fileNames = unzip(fileName, directory);
    assert(numel(fileNames) == 1);

    text = func(fileNames{1});

    delete(fullfile(directory, '*'));
    rmdir(directory);
end