% Eli Bowen
% 2/27/2020
% wrapper around the hmax library
% https://maxlab.neuro.georgetown.edu/hmax.html
% the data types produced by extractC2forCell make zero sense, and had no type safety - so here's my own version
% INPUTS:
%   img - one image (in a valid matlab image format), or a cell array of said images (not sure what the outputs look like in that case)
%   patchCache - OPTIONAL struct returned from this function in a previous call - reuse for efficiency
%   nOrientations - OPTIONAL scalar (numeric) - if passed, must be 4 or 6 (default = 4)
%   nScales - OPTIONAL scalar (numeric) - if passed, must be 1, 2, 4, or 8 (default = 8)
% RETURNS:
%   s1 - s1{nBands,nScalesPerBand,nFilters}(:,:) contains a gabor's responses at each location on the image
%   c1 - c1{nBands}(:,:,nFilters) contains ___
%   s2 - s2{nPatchesPerSz,nPatchSizes}{nBands} contains ___
%   c2 - c2(nPatchesPerSz,nPatchSizes) contains ___
%   bestBands
%   bestLocations
%   patchCache
function [s1,c1,s2,c2,bestBands,bestLocations,patchCache] = HMAX (img, patchCache, nOrientations, nScales)
    validateattributes(img, {'numeric'}, {'nonempty'});
    assert(size(img, 3) == 1, 'img must be grayscale - if handling color, call HMAX on each channel separately');
    if ~isa(img, 'double')
        assert(isa(img, 'uint8'));
        img = im2double(img); %image must be double
    end
    assert(max(img(:)) <= 1, 'img must be ranged 0-->1');
    if ~exist('nScales', 'var') || isempty(nScales)
        nScales = 8; % originally, this was the only choice
    end

    %% init S1 gabor filters
    if ~exist('patchCache', 'var') || isempty(patchCache)
        patchCache = load('universal_patch_set.mat', 'patches', 'patchSizes'); % mat file should be in path (found in ?/MatlabCommon/frontends/img_hmax/ folder)
        
        % init S1 gabor filters
        if ~exist('nOrientations', 'var') || isempty(nOrientations) || nOrientations == 4 % original option
            orientations = [0,45,90,135];
        elseif nOrientations == 6
            orientations = [0,30,60,90,120,150];
            warning('HMAX.m: untested nOrientations==6');
        else
            error('unexpected nOrientations');
        end
        [patchCache.filter_sz,patchCache.filters,patchCache.sqfilter,~,patchCache.filter_orientations] = initGabor(orientations);
    end

    %% C1
    if nScales == 8
        c1Scale = 1:2:17; % defining 8 scale bands; there are 17 patches available in the patch cache
        c1Space = 8:2:22; % defining spatial pooling range for each scale band
    elseif nScales == 4
        c1Scale = 1:4:17;
        c1Space = 8:4:22; % defining spatial pooling range for each scale band
        warning('HMAX.m: untested nScales setting');
    elseif nScales == 2
        c1Scale = 1:8:17;
        c1Space = 8:8:22; % defining spatial pooling range for each scale band
        warning('HMAX.m: untested nScales setting');
    elseif nScales == 1
        c1Scale = 1;
        c1Space = 8;
        warning('HMAX.m: untested nScales setting');
    else
        error('unexpected nScales');
    end
    includeBorders = true;
    if nargout() == 1
        s1      = C1(img, patchCache.sqfilter, patchCache.filter_sz, c1Space, c1Scale, includeBorders);
    else
        [s1,c1] = C1(img, patchCache.sqfilter, patchCache.filter_sz, c1Space, c1Scale, includeBorders);
    end

    if nargout() > 2
        %% for each patch calculate C2 unit responses
        nPatchSizes   = size(patchCache.patchSizes, 2);
        nPatchesPerSz = size(patchCache.patches{1}, 2);

        s2            = cell(nPatchesPerSz, nPatchSizes);
        c2            = zeros(nPatchesPerSz, nPatchSizes);
        bestBands     = zeros(nPatchesPerSz, nPatchSizes);
        bestLocations = zeros(nPatchesPerSz, 2, nPatchSizes);

        ignorePartials       = false; % dunno what this does - false was default
        allS2C1Prune         = false; % dunno what this does - false was default
        orientations2C1Prune = false; % dunno what this does - false was default
        for i = 1:nPatchSizes
            [s2(:,i),c2(:,i),bestBands(:,i),bestLocations(:,:,i)] =...
                C2(img, patchCache.filter_sz, c1Space, c1Scale, patchCache.patches{i}, patchCache.patchSizes(1:3,i)', c1, ignorePartials, allS2C1Prune, orientations2C1Prune);
        end
    end
end