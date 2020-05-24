%Eli Bowen
%4/25/2020
%INPUTS:
%   filePath
%   colorScheme - 'gray', 'rgb', 'opponency', 'retinalgray', 'retinalrgb', 'retinalopponency'
%   scaleFactor - OPTIONAL - scale the images while loading!
function [count,descriptors,imgs] = GetImgs (filePath, colorScheme, scaleFactor)
    validateattributes(filePath, {'char'}, {'nonempty'});
    validateattributes(colorScheme, {'char'}, {'nonempty'});
    if ~exist('scaleFactor', 'var')
        scaleFactor = [];
    end
    
    fullCount = CountFileType(filePath, 'png');
    descriptors = cell(1, fullCount);
    [count,descriptors,imgs] = GetImgsHelper(filePath, colorScheme, scaleFactor, 0, fullCount, descriptors, [], '');
end


%gonna do this recursively
function [count,descriptors,imgs] = GetImgsHelper (filePath, colorScheme, scaleFactor, count, fullCount, descriptors, imgs, append)
    listing = dir(filePath);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                [count,descriptors,imgs] = GetImgsHelper(fullfile(filePath, listing(i).name), colorScheme, scaleFactor, count, fullCount, descriptors, imgs, [append,'_',strrep(listing(i).name, '_', '-')]);
            elseif ~isempty(regexp(listing(i).name, '\.png$', 'ignorecase', 'ONCE'))
                count = count + 1;
                descriptors{count} = strrep(regexprep(lower(listing(i).name), '\.png$', ''), '_', '-');
                if ~isempty(append)
                    descriptors{count} = [append,'_',descriptors{count}];
                end
                img = imread(fullfile(filePath,listing(i).name));
                if ~isempty(scaleFactor)
                    img = imresize(img, scaleFactor);
                end
                img = im2double(img);
                if strcmp(colorScheme, 'gray')
                    img = 0.2989 .* img(:,:,1) + 0.5870 .* img(:,:,2) + 0.1140 .* img(:,:,3);
                elseif strcmp(colorScheme, 'rgb')
                    %nothing to do
                elseif strcmp(colorScheme, 'opponency')
                    img = RGB2Opponent(img);
                elseif strcmp(colorScheme, 'retinalgray')
                    retina = VideoRetina(size(img, 1), size(img, 2), false); %prints lots of junk
                    [img,~] = retina.ProcessFrame(img);
                elseif strcmp(colorScheme, 'retinalrgb')
                    retina = VideoRetina(size(img, 1), size(img, 2), true); %prints lots of junk
                    [img,~] = retina.ProcessFrame(img);
                elseif strcmp(colorScheme, 'retinalopponency')
                    retina = VideoRetina(size(img, 1), size(img, 2), true); %prints lots of junk
                    [img,~] = retina.ProcessFrame(img);
                    img = RGB2Opponent(img);
                else
                    error('unknown colorScheme');
                end
                
                if isempty(imgs)
                    if strcmp(colorScheme, 'gray') || strcmp(colorScheme, 'retinalgray')
                        imgs = zeros(size(img, 1), size(img, 2), fullCount);
                    else
                        imgs = zeros(size(img, 1), size(img, 2), 3, fullCount);
                    end
                end
                
                if strcmp(colorScheme, 'gray') || strcmp(colorScheme, 'retinalgray')
                    imgs(:,:,count) = img;
                else
                    imgs(:,:,:,count) = img;
                end
            end
        end
    end
end
