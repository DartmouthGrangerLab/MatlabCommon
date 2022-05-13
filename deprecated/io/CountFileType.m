% deprecated
function [count,filePath] = CountFileType (path, extension, isRecursive)
    validateattributes(path, {'char'}, {'nonempty','vector'});
    validateattributes(extension, {'char'}, {'nonempty','vector'});
    if ~exist('isRecursive', 'var') || isempty(isRecursive)
        isRecursive = true;
    end
    validateattributes(isRecursive, {'logical'}, {'nonempty','scalar'});
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
        count = CountFileTypeHelper1(path, ext{i}, count, isRecursive);
    end
    filePath = cell(1, count);
    count = 0; % now reset counter
    for i = 1:numel(ext)
        [count,filePath] = CountFileTypeHelper2(path, ext{i}, count, filePath, isRecursive);
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


function [count] = CountFileTypeHelper1 (path, extension, count, isRecursive)
    listing = dir(path);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                if isRecursive
                    count = CountFileTypeHelper1(fullfile(path, listing(i).name), extension, count, isRecursive);
                end
            elseif ~isempty(regexp(listing(i).name, ['\.',extension,'$'], 'ignorecase', 'ONCE'))
                count = count + 1;
            end
        end
    end
end


function [count,filePath] = CountFileTypeHelper2 (path, extension, count, filePath, isRecursive)
    listing = dir(path);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                if isRecursive
                    [count,filePath] = CountFileTypeHelper2(fullfile(path, listing(i).name), extension, count, filePath, isRecursive);
                end
            elseif ~isempty(regexp(listing(i).name, ['\.',extension,'$'], 'ignorecase', 'ONCE'))
                count = count + 1;
                filePath{count} = fullfile(path, listing(i).name);
            end
        end
    end
end