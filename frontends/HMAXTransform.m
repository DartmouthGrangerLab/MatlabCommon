% Eli Bowen 10/2021
% gpu isnt faster due to all the for loops in HMAX
% INPUTS:
%   img - n_rows x n_cols x n_chan x n_imgs (images; double 0 --> 1 or uint8)
%   type - (char) 's1' or 'c1'
% RETURNS:
%   hmax
% see also: HMAX
function [hmax] = HMAXTransform(img, type)
    validateattributes(img, {'logical','numeric'}, {});
    validateattributes(type, 'char', {'nonempty'});
    n = size(img, 4);
    imgSz = [size(img, 1),size(img, 2),size(img, 3)]; % [n_rows,n_cols,n_chan]

    patchCache = HMAXPatchCache([0,45,90,135], 2, img);
    hmaxImgSz = [imgSz(1)/2,imgSz(2)/2,imgSz(3)*4]; % 1/4 as many pixels as 28 x 28 (makes up for 4x as many channels)

    hmax = zeros(hmaxImgSz(1), hmaxImgSz(2), hmaxImgSz(3), n);

%     parfor i = 1 : n % parfor works ok, can overload RAM
    for i = 1 : n
        temp = imresize(img(:,:,:,i), 6, 'nearest');
        for j = 1 : imgSz(3) % for each channel
            if strcmp(type, 's1')
                s1 = HMAX(temp(:,:,j), patchCache, true);
                hmax(:,:,(j-1)*4 + 1,i) = imresize(s1{1,1,1}, hmaxImgSz(1:2));
                hmax(:,:,(j-1)*4 + 2,i) = imresize(s1{1,1,2}, hmaxImgSz(1:2));
                hmax(:,:,(j-1)*4 + 3,i) = imresize(s1{1,1,3}, hmaxImgSz(1:2));
                hmax(:,:,(j-1)*4 + 4,i) = imresize(s1{1,1,4}, hmaxImgSz(1:2));
            elseif strcmp(type, 'c1')
                [~,c1] = HMAX(temp(:,:,j), patchCache, true);
                hmax(:,:,(j-1)*4 + (1:4),i) = imresize(c1{1}, hmaxImgSz(1:2));
            else
                error('unexpected type');
            end
        end
    end

%     figure;
%     for i = 1 : n_classes
%         subplot_tight(n_classes, 4, 4*(i-1)+1); imshow(img(:,:,i));
%         [~,c1] = HMAX(temp(:,:,i), patchCache, true);
%         c1{1} = cat(3, imresize(c1{1}(:,:,1), hmaxImgSz), imresize(c1{1}(:,:,2), hmaxImgSz), imresize(c1{1}(:,:,3), hmaxImgSz), imresize(c1{1}(:,:,4), hmaxImgSz));
%         c1{2} = cat(3, imresize(c1{2}(:,:,1), hmaxImgSz), imresize(c1{2}(:,:,2), hmaxImgSz), imresize(c1{2}(:,:,3), hmaxImgSz), imresize(c1{2}(:,:,4), hmaxImgSz));
%         [~,idx] = maxk(c1{1}(:), spikingPixelCount(i));
%         c1{1}(:) = 0;
%         c1{1}(idx) = 1;
%         [~,idx] = maxk(c1{2}(:), spikingPixelCount(i));
%         c1{2}(:) = 0;
%         c1{2}(idx) = 1;
%         subplot_tight(n_classes, 4, 4*(i-1)+2); imshow(c1{1}(:,:,1:3));
%         subplot_tight(n_classes, 4, 4*(i-1)+3); imshow(c1{2}(:,:,1:3));
%     end
end