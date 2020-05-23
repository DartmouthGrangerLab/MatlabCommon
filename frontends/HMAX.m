%Eli Bowen
%2/27/2020
%wrapper around the hmax library
%https://maxlab.neuro.georgetown.edu/hmax.html
%the data types produced by extractC2forCell make zero sense, and had no type safety - so here's my own version
%INPUTS:
%   img - one image (in a valid matlab image format), or a cell array of said images (not sure what the outputs look like in that case)
%   patchCache - OPTIONAL struct returned from this function in a previous call - reuse for efficiency
%RETURNS:
%   s1 - s1{numbands,numscalesperband,numfilters}(:,:) contains a gabor's responses at each location on the image
%   c1 - c1{numbands}(:,:,numfilters) contains ___
%   s2 - s2{numpatchespersize,numpatchsizes}{numbands} contains ___
%   c2 - c2(numpatchespersize,numpatchsizes) contains ___
function [s1,c1,s2,c2,bestBands,bestLocations,patchCache] = HMAX (img, patchCache)
    validateattributes(img, {'numeric'}, {'nonempty'});
    
    %% init S1 gabor filters
    if ~exist('patchCache', 'var') || isempty(patchCache)
        patchCache = load('universal_patch_set.mat', 'patches', 'patchSizes'); %mat file should be in path (found in ?/MatlabCommon/frontends/img_hmax/ folder)
        
        %init S1 gabor filters
        orientations = [0,45,90,135]; % 4 orientations for gabor filters
%         orientations = [90,-45,0,45]; % 4 orientations for gabor filters
        RFsize       = 7:2:39;        % receptive field sizes
        div          = 4:-.05:3.2;    % tuning parameters for the filters' "tightness"
        [patchCache.filterSizes,patchCache.filters,patchCache.sqfilter,patchCache.c1OL,~,patchCache.filterOrientations] = initGabor(orientations, RFsize, div);
    end
    
    %% make sure image is in valid format
    if size(img, 3) == 3
        img = rgb2gray(img); %image must be grayscale
    end
    if ~isa(img, 'double')
        img = im2double(img); %image must be double
    end
    assert(max(img(:)) <= 1, 'img must be ranged 0-->1');
    
    %% C1
    includeBorders = true;
    c1Scale = 1:2:18; % defining 8 scale bands
    c1Space = 8:2:22; % defining spatial pooling range for each scale band
    [c1,s1] = C1(img, patchCache.sqfilter, patchCache.filterSizes, c1Space, c1Scale, patchCache.c1OL, includeBorders);
    
    if nargout > 2
        %% for each patch calculate C2 unit responses
        nPatchSizes     = size(patchCache.patchSizes, 2);
        nPatchesPerSize = size(patchCache.patches{1}, 2);

        s2            = cell(nPatchesPerSize, nPatchSizes);
        c2            = zeros(nPatchesPerSize, nPatchSizes);
        bestBands     = zeros(nPatchesPerSize, nPatchSizes);
        bestLocations = zeros(nPatchesPerSize, 2, nPatchSizes);

        ignorePartials       = false; %dunno what this does - false was default
        allS2C1Prune         = false; %dunno what this does - false was default
        orientations2C1Prune = false; %dunno what this does - false was default
        for i = 1:nPatchSizes
            [c2(:,i),s2(:,i),bestBands(:,i),bestLocations(:,:,i)] =...
                C2(img, patchCache.filterSizes, c1Space, c1Scale, patchCache.patches{i}, patchCache.patchSizes(1:3,i)', c1, ignorePartials, allS2C1Prune, orientations2C1Prune);
        end
    end
end
