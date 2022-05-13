% deprecated
function [count,descriptors,imgsFiltered] = GetImgs (path, filter, resizeParam)
    validateattributes(path, {'char'}, {'nonempty'});
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
    
    fullCount = CountFileType(path, 'png');
    descriptors = cell(1, fullCount);
    [count,descriptors,imgs] = Helper(path, resizeParam, 0, fullCount, descriptors, [], '');
    
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
function [count,descriptors,imgs] = Helper (path, resizeParam, count, fullCount, descriptors, imgs, append)
    listing = dir(path);
    for i = 1:numel(listing)
        if listing(i).isdir && ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            [count,descriptors,imgs] = Helper(fullfile(path, listing(i).name), resizeParam, count, fullCount, descriptors, imgs, [append,'_',strrep(listing(i).name, '_', '-')]);
        end
    end
    for i = 1:numel(listing)
        if ~listing(i).isdir
            [~,fileNameNoExt,ext] = fileparts(listing(i).name);
            if strcmpi(ext, '.png')
                img = imread(fullfile(path, listing(i).name));
                if ~isempty(resizeParam)
                    img = imresize(img, resizeParam);
                end
                if isempty(imgs)
                    imgs = zeros(size(img, 1), size(img, 2), 3, fullCount);
                end
                imgs(:,:,:,count+1) = img;

                descriptors{count+1} = strrep(lower(fileNameNoExt), '_', '-');
                if ~isempty(append)
                    descriptors{count+1} = [append,'_',descriptors{count+1}];
                end
                count = count + 1;
            end
        end
    end
end
