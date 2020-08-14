%Eli Bowen
%4/25/2020
%INPUTS:
%   filePath
%   filter - OPTIONAL - any option to ImgFilter, e.g. 'rgb2gray', 'opponency', 'retina', 'retinagray', 'gabor'
%   resizeParam - OPTIONAL - scale the images while loading! (if scalar, this is a scaling factor e.g. 2 = double, if 1x2, this is desiredSize = [nRows,nCols])
function [count,descriptors,imgsFiltered] = GetImgs (filePath, filter, resizeParam)
    validateattributes(filePath, {'char'}, {'nonempty'});
    if ~exist('resizeParam', 'var')
        resizeParam = [];
    end
    if numel(resizeParam) == 1 % scale factor
        validateattributes(resizeParam, {'numeric'}, {'nonempty','scalar','positive'});
    elseif numel(resizeParam) == 2 % nRows x nCols desired
        validateattributes(resizeParam, {'numeric'}, {'nonempty','vector','positive','integer'});
    else
        assert(isempty(resizeParam)); % only 2 options are above
    end
    
    fullCount = CountFileType(filePath, 'png');
    descriptors = cell(1, fullCount);
    [count,descriptors,imgs] = GetImgsHelper(filePath, scaleFactor, resizeParam, 0, fullCount, descriptors, [], '');
    
    if exist('filter', 'var') && ~isempty(filter)
        f = ImgFilter(filter, 'rgb');
        if f.nOutChannels == 1
            imgsFiltered = zeros(size(imgs, 1), size(imgs, 2), fullCount);
        else
            imgsFiltered = zeros(size(imgs, 1), size(imgs, 2), f.nOutChannels, fullCount);
        end
        for i = 1:fullCount
            img = f.Proc(imgs(:,:,:,i));
            if f.nOutChannels == 1
                imgsFiltered(:,:,i) = img;
            else
                imgsFiltered(:,:,:,i) = img;
            end
        end
    else
        imgsFiltered = imgs;
    end
end


%gonna do this recursively
function [count,descriptors,imgs] = GetImgsHelper (filePath, resizeParam, count, fullCount, descriptors, imgs, append)
    listing = dir(filePath);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                [count,descriptors,imgs] = GetImgsHelper(fullfile(filePath, listing(i).name), resizeParam, count, fullCount, descriptors, imgs, [append,'_',strrep(listing(i).name, '_', '-')]);
            elseif ~isempty(regexp(listing(i).name, '\.png$', 'ignorecase', 'ONCE'))
                count = count + 1;
                descriptors{count} = strrep(regexprep(lower(listing(i).name), '\.png$', ''), '_', '-');
                if ~isempty(append)
                    descriptors{count} = [append,'_',descriptors{count}];
                end
                img = imread(fullfile(filePath,listing(i).name));
                if ~isempty(resizeParam)
                    img = imresize(img, resizeParam);
                end
                if isempty(imgs)
                    imgs = zeros(size(img, 1), size(img, 2), 3, fullCount);
                end
                imgs(:,:,:,count) = img;
            end
        end
    end
end
