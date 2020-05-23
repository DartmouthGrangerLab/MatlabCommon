%Eli Bowen
%4/25/2020
%used to be "CountImgs", which only counted pngs
%INPUTS:
%   filePath
%   extension
function [count] = CountFileType (filePath, extension)
    validateattributes(filePath, {'char'}, {'nonempty'});
    if ~exist('extension', 'var') || isempty(extension)
        extension = 'png';
    end
    
    count = CountImgsHelper(filePath, extension, 0);
end


function [count] = CountImgsHelper (filePath, extension, count)
    listing = dir(filePath);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                count = CountImgs(fullfile(filePath,listing(i).name), extension, count);
            elseif ~isempty(regexp(listing(i).name, ['\.',extension,'$'], 'ignorecase', 'ONCE'))
                count = count + 1;
            end
        end
    end
end