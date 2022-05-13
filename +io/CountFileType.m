% Eli Bowen 4/25/2020
% used to be "CountImgs", which only counted pngs
% INPUTS
%   path         - (char)
%   extension    - (char) file extension (no dot), or one of the following: 'image', 'video', 'audio'
%   is_recursive - OPTIONAL scalar (logical) - if true, will search in subfolders (default = true)
% RETURNS
%   count - scalar double - number of files found
%   filePath - 1 x count cell array of chars - list of files found - full path including folder and file name
function [count,filePath] = CountFileType(path, extension, is_recursive)
    validateattributes(path, {'char'}, {'nonempty','vector'}, 1);
    validateattributes(extension, {'char'}, {'nonempty','vector'}, 2);
    if ~exist('is_recursive', 'var') || isempty(is_recursive)
        is_recursive = true;
    end
    validateattributes(is_recursive, {'logical'}, {'nonempty','scalar'});
    if startsWith(extension, '.')
        extension = extension(2:end);
    end

    if strcmp(extension, 'image')
        ext = {'png','jpg','jpeg','tiff','bmp'};
    elseif strcmp(extension, 'video')
        ext = {'avi','mj2','mpg','mov','m4v','mp4'}; % mp4's are inspected - only video-containing ones are kept
    elseif strcmp(extension, 'audio')
        ext = {'wav','ogg','flac','mp3','m4a','mp4'}; % mp4's are inspected - they're audio only if they contain no video
    else
        ext = {extension};
    end

    count = 0;
    for i = 1:numel(ext)
        count = Helper1(path, ext{i}, count, is_recursive);
    end
    filePath = cell(1, count);
    count = 0; % now reset counter
    for i = 1:numel(ext)
        [count,filePath] = Helper2(path, ext{i}, count, filePath, is_recursive);
    end

    % remove mp4s that contain the wrong kind of content
    if strcmp(extension, 'video') || strcmp(extension, 'audio')
        keep = true(1, count);
        for i = 1:count
            [~,~,ext] = fileparts(filename);
            if strcmpi(ext, 'mp4')
                temp = mmfileinfo(filePath{i});
                if (strcmp(extension, 'video') && isempty(temp.Video.Format)) || (strcmp(extension, 'audio') && ~isempty(temp.Video.Format))
                    keep(i) = false;
                end
            end
        end
        filePath = filePath(keep);
        count = numel(filePath);
    end
end


function count = Helper1(path, extension, count, is_recursive)
    listing = dir(path);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                if is_recursive
                    count = CountFileTypeHelper1(fullfile(path, listing(i).name), extension, count, is_recursive);
                end
            elseif ~isempty(regexp(listing(i).name, ['\.',extension,'$'], 'ignorecase', 'ONCE'))
                count = count + 1;
            end
        end
    end
end


function [count,filePath] = Helper2(path, extension, count, filePath, is_recursive)
    listing = dir(path);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                if is_recursive
                    [count,filePath] = CountFileTypeHelper2(fullfile(path, listing(i).name), extension, count, filePath, is_recursive);
                end
            elseif ~isempty(regexp(listing(i).name, ['\.',extension,'$'], 'ignorecase', 'ONCE'))
                count = count + 1;
                filePath{count} = fullfile(path, listing(i).name);
            end
        end
    end
end