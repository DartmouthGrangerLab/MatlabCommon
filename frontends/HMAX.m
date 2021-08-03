% Eli Bowen
% 2/27/2020
% wrapper around the hmax library
% https://maxlab.neuro.georgetown.edu/hmax.html
% the data types produced by extractC2forCell make zero sense, and had no type safety - so here's my own version
% INPUTS:
%   img - one image (in a valid matlab image format), or a cell array of said images (not sure what the outputs look like in that case)
%   patchCache - OPTIONAL struct returned from this function in a previous call - reuse for efficiency
%   orientations - OPTIONAL 1 x nOrientations (numeric) - gabor angles in degrees, default = [0,45,90,135], good alternative for hex grids = [0,30,60,90,120,150]
%   nBands - OPTIONAL scalar (int-valued numeric) - default = 8
% RETURNS:
%   s1 - s1{nBands,nScalesPerBand,nOrientations}(:,:) contains a gabor's responses at each location on the image
%   c1 - c1{nBands}(:,:,nOrientations) contains ___
%   s2 - s2{nBands,nPatchesPerSz,nPatchSizes} contains ___
%   c2 - c2(nPatchesPerSz,nPatchSizes) contains ___
%   bestBands
%   bestLocations
%   patchCache
function [s1,c1,s2,c2,bestBands,bestLocations,patchCache] = HMAX (img, patchCache, orientations, nBands)
    validateattributes(img, {'numeric'}, {'nonempty'});
    assert(size(img, 3) == 1, 'img must be grayscale - if handling color, call HMAX on each channel separately');
    if ~isa(img, 'double')
        assert(isa(img, 'uint8'));
        img = im2double(img); % image must be double
    end
    assert(max(img(:)) <= 1, 'img must be ranged 0-->1');
    if ~exist('orientations', 'var') || isempty(orientations)
        orientations = [0,45,90,135]; % originally, this was the only choice
    end
    if ~exist('nBands', 'var') || isempty(nBands)
        nBands = 8; % originally, this was the only choice
    end

    %% init S1 gabor filters
    if ~exist('patchCache', 'var') || isempty(patchCache)
        validateattributes(orientations, {'numeric'}, {'nonempty','vector'});
        validateattributes(nBands, {'numeric'}, {'nonempty','scalar','positive','integer'});
        nScalesPerBand = 2; % a bit messy to make variable

        patchCache = struct();
        patchCache.orientations   = orientations;
        patchCache.nBands         = nBands;
        patchCache.nScalesPerBand = nScalesPerBand;

        % for S1, C1
        sz = 7:2:5+2*nScalesPerBand*nBands; % a list of receptive field sizes for the filters
        gamma = 0.3; % spatial aspect ratio: 0.23 < gamma < 0.92
        patchCache.sqfilter           = cell(numel(orientations), nBands*nScalesPerBand);  % IMPORTANT that this is nOrientations x nSizes not vice-versa (for linear indexing later)
        patchCache.filter_orientation = zeros(numel(orientations), nBands*nScalesPerBand); % IMPORTANT that this is nOrientations x nSizes not vice-versa (for linear indexing later)
        patchCache.filter_sz          = zeros(numel(orientations), nBands*nScalesPerBand); % IMPORTANT that this is nOrientations x nSizes not vice-versa (for linear indexing later)
        for i = 1:nBands*nScalesPerBand
            for r = 1:numel(orientations)
                patchCache.sqfilter{r,i} = InitGabor(orientations(r), sz(i), gamma);
                patchCache.filter_orientation(r,i) = orientations(r);
                patchCache.filter_sz(r,i) = sz(i);
            end
        end
        patchCache.c1Scale = 1:nScalesPerBand:nScalesPerBand*nBands; % defining 8 scale bands with 2 scales each; there are 17 patches available in the patch cache
        patchCache.c1Space = 8:nScalesPerBand:8+nScalesPerBand*(nBands-1); % defining spatial pooling range for each scale band
        assert(nBands * nScalesPerBand == patchCache.c1Scale(end) + 1); % remember, last element in c1Scale is max scale - 1
        %   c1Scale: (for C1 units) a vector, defines the scale bands, a group of
        %       filter sizes over which a local max is taken to get C1 unit responses.
        %       ex. c1Scale = [1 k num_filters+1] means 2 bands, the first with
        %       filters(:,1:k-1) and the second with filters(:,k:num_filters).
        %       If N bands, make length(c1Scale) = N+1.
        %   c1Space: (for C1 units) a vector, defines the spatial pooling range of
        %       each scale band, ex. c1Space(i) = m means that each C1 unit response in
        %       band i is obtained by taking a max over a neighborhood of m x m S1 units.
        %       If N bands, make length(c1Space) = N.
        
        % for S2, C2
        load('universal_patch_set.mat', 'patches'); % mat file should be in path (found in ?/MatlabCommon/frontends/img_hmax/ folder)
        load('universal_patch_set.mat', 'patchSizes'); % mat file should be in path (found in ?/MatlabCommon/frontends/img_hmax/ folder)
        patchCache.patches = patches; % 1 x 8 (cell)
        patchCache.patch_sz = patchSizes(1:3,:); % patchCache.patch_sz == [2,4,6,8,10,12,14,16;2,4,6,8,10,12,14,16;4,4,4,4,4,4,4,4]
    end

    %% C1
    isIncludeBorder = true; % true is the original default
    if nargout() == 1
        s1      = C1(img, patchCache.c1Space, patchCache.sqfilter, isIncludeBorder);
    else
        [s1,c1] = C1(img, patchCache.c1Space, patchCache.sqfilter, isIncludeBorder);
    end

    %% for each patch calculate C2 unit responses
    if nargout() > 2
        assert(all(patchCache.orientations == [0,45,90,135])); % only option - this is the set of parameters under which the patches were generated
        assert(patchCache.nBands == 8 && patchCache.nScalesPerBand == 2); % not sure what'll happen if we change this from the default - the code is super hacky
        
        nPatchSizes   = size(patchCache.patch_sz, 2);
        nPatchesPerSz = size(patchCache.patches{1}, 2);

        s2            = cell(nBands, nPatchesPerSz, nPatchSizes);
        c2            = zeros(nPatchesPerSz, nPatchSizes);
        bestBands     = zeros(nPatchesPerSz, nPatchSizes);
        bestLocations = zeros(nPatchesPerSz, 2, nPatchSizes);

        isIgnorePartials     = false; % dunno what this does - false was default
        allS2C1Prune         = 0; % dunno what this does - 0 was default
        orientations2C1Prune = 0; % dunno what this does - 0 was default
        for i = 1:nPatchSizes
            [s2(:,:,i),c2(:,i),bestBands(:,i),bestLocations(:,:,i)] =...
                C2(img, patchCache.c1Space, patchCache.c1Scale, patchCache.filter_sz, patchCache.patches{i}, patchCache.patch_sz(:,i)', c1, isIgnorePartials, allS2C1Prune, orientations2C1Prune);
        end
    end
end