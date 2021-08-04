% Eli Bowen
% 2/27/2020
% wrapper around the hmax library
% https://maxlab.neuro.georgetown.edu/hmax.html
% the data types produced by extractC2forCell make zero sense, and had no type safety - so here's my own version
% patchCache = HMAXPatchCache(orientations, nBands);
% [s1,c1] = HMAX(img, patchCache)
% [s1,c1,s2,c2,bestBands,bestLocations] = HMAX(img, patchCache);
% INPUTS:
%   img - one image (in a valid matlab image format), or a cell array of said images (not sure what the outputs look like in that case)
%   patchCache - OPTIONAL struct returned from a call to HMAXPatchCache() - reuse for efficiency
% RETURNS:
%   s1 - s1{nBands,nScalesPerBand,nOrientations}(:,:) contains a gabor's responses at each location on the image
%   c1 - c1{nBands}(:,:,nOrientations) contains ___
%   s2 - s2{nBands,nPatchesPerSz,nPatchSizes} contains ___
%   c2 - c2(nPatchesPerSz,nPatchSizes) contains ___
%   bestBands
%   bestLocations
function [s1,c1,s2,c2,bestBands,bestLocations] = HMAX (img, patchCache)
    validateattributes(img, {'numeric'}, {'nonempty'});
    assert(size(img, 3) == 1, 'img must be grayscale - if handling color, call HMAX on each channel separately');
    if ~isa(img, 'double')
        assert(isa(img, 'uint8'));
        img = im2double(img); % image must be double
    end
    assert(max(img(:)) <= 1, 'img must be ranged 0-->1');

    %% init S1 gabor filters
    if ~exist('patchCache', 'var') || isempty(patchCache)
        patchCache = HMAXPatchCache([0,45,90,135], 8); % originally, these params were the only choices
    end

    %% C1
    isIncludeBorder = true; % true is the original default
    if nargout() == 1
        s1      = C1(img, patchCache.c1_space, patchCache.sqfilter, isIncludeBorder);
    else
        [s1,c1] = C1(img, patchCache.c1_space, patchCache.sqfilter, isIncludeBorder);
    end

    %% for each patch calculate C2 unit responses
    if nargout() > 2
        assert(all(patchCache.orientations == [0,45,90,135])); % only option - this is the set of parameters under which the patches were generated
        assert(patchCache.nBands == 8 && patchCache.nScalesPerBand == 2); % not sure what'll happen if we change this from the default - the code is super hacky

        nPatchSizes   = size(patchCache.patch_sz, 2);
        nPatchesPerSz = size(patchCache.patches{1}, 2);

        s2            = cell(patchCache.nBands, nPatchesPerSz, nPatchSizes);
        c2            = zeros(nPatchesPerSz, nPatchSizes);
        bestBands     = zeros(nPatchesPerSz, nPatchSizes);
        bestLocations = zeros(nPatchesPerSz, 2, nPatchSizes);

        isIgnorePartials     = false; % dunno what this does - false was default
        allS2C1Prune         = 0; % dunno what this does - 0 was default
        orientations2C1Prune = 0; % dunno what this does - 0 was default
        for i = 1:nPatchSizes
            [s2(:,:,i),c2(:,i),bestBands(:,i),bestLocations(:,:,i)] =...
                C2(img, patchCache.c1_space, patchCache.c1_scale, patchCache.filter_sz, patchCache.patches{i}, patchCache.patch_sz(:,i)', c1, isIgnorePartials, allS2C1Prune, orientations2C1Prune);
        end
    end
end