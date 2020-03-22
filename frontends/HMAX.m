%Eli Bowen
%2/27/2020
%wrapper around the hmax library
%INPUTS:
%   img - one image (in a valid matlab image format), or a cell array of said images (not sure what the outputs look like in that case)
%   patchCache - OPTIONAL struct returned from this function in a previous call - reuse for efficiency
function [c2,c1,bestBands,bestLocations,s2,s1,patchCache] = HMAX (img, patchCache)
    validateattributes(img, {'cell','numeric'}, {'nonempty'});
    if ~exist('patchCache', 'var') || isempty(patchCache)
        patchCache = load('universal_patch_set.mat', 'patches', 'patchSizes'); %mat file should be in path (found in ?/MatlabCommon/frontends/img_hmax/ folder)
        
        %init S1 gabor filters
        orientations = [90,-45,0,45]; % 4 orientations for gabor filters
        RFsizes      = 7:2:39;        % receptive field sizes
        div          = 4:-.05:3.2;    % tuning parameters for the filters' "tightness"
        [patchCache.filterSizes,patchCache.filters,patchCache.c1OL,~] = initGabor(orientations, RFsizes, div);
    end

    %% C1 parameters
    c1Scale = 1:2:18; % defining 8 scale bands
    c1Space = 8:2:22; % defining spatial pooling range for each scale band
    
    %% make sure images are in valid format
    if iscell(img)
        for i = 1:numel(img)
            img{i} = double(rgb2gray(img{i})); %image must be grayscale, double
        end
    else
        img = double(rgb2gray(img)); %image must be grayscale, double
    end
    
    %% for each patch calculate unit responses
    nPatchSizes = size(patchCache.patchSizes, 2);
    [c2,c1,bestBands,bestLocations,s2,s1] = extractC2forCell(patchCache.filters, patchCache.filterSizes, c1Space, c1Scale, patchCache.c1OL, patchCache.patches, img, nPatchSizes, patchCache.patchSizes(1:3,:));
end