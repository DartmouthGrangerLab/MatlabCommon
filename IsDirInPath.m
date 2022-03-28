% Eli Bowen 1/27/2021
% checks whether a folder/directory is in matlab's current path
% a fixed version of https://stackoverflow.com/questions/23524708/how-to-check-if-a-folder-is-on-the-search-path
% INPUTS:
%   dirPath - relative or absolute path of the directory
% RETURNS:
%   tf - scalar (logical)
function tf = IsDirInPath(dirPath)
    path_list_cell = regexp(path(), pathsep(), 'Split');
    tf = any(endsWith(path_list_cell, dirPath));
end