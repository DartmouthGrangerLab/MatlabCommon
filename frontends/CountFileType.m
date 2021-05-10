% Eli Bowen
% 4/25/2020
% used to be "CountImgs", which only counted pngs
% INPUTS:
%   path
%   extension - file extension (no dot), or one of the following: 'image', 'video', 'audio'
% RETURNS:
%   count - scalar double - number of files found
%   filePath - 1 x count cell array of chars - list of files found - full path including folder and file name
function [count,filePath] = CountFileType (path, extension)
    validateattributes(path, {'char'}, {'nonempty','vector'});
    validateattributes(extension, {'char'}, {'nonempty','vector'});

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
        count = CountFileTypeHelper1(path, ext{i}, count);
    end
    filePath = cell(1, count);
    count = 0; % now reset counter
    for i = 1:numel(ext)
        [count,filePath] = CountFileTypeHelper2(path, ext{i}, count, filePath);
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


function [count] = CountFileTypeHelper1 (path, extension, count)
    listing = dir(path);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                count = CountFileTypeHelper1(fullfile(path, listing(i).name), extension, count, filePath);
            elseif ~isempty(regexp(listing(i).name, ['\.',extension,'$'], 'ignorecase', 'ONCE'))
                count = count + 1;
            end
        end
    end
end


function [count,filePath] = CountFileTypeHelper2 (path, extension, count, filePath)
    listing = dir(path);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                [count,filePath] = CountFileTypeHelper2(fullfile(path, listing(i).name), extension, count, filePath);
            elseif ~isempty(regexp(listing(i).name, ['\.',extension,'$'], 'ignorecase', 'ONCE'))
                count = count + 1;
                filePath{count} = fullfile(path, listing(i).name);
            end
        end
    end
end