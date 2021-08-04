% see HMAX.m
% INPUTS:
%   orientations - OPTIONAL 1 x nOrientations (numeric) - gabor angles in degrees, default = [0,45,90,135], good alternative for hex grids = [0,30,60,90,120,150]
%   nBands - OPTIONAL scalar (int-valued numeric) - default = 8
% RETURNS:
%   patchCache - struct with below fields:
%       .orientations - vector (numeric) - copy of corresponding input param
%       .nBands - scalar (numeric) - copy of corresponding input param
%       .nScalesPerBand - scalar (numeric)
%       .sqfilter - nBands*nScalesPerBand (cell)
%       .filter_orientation - nBands*nScalesPerBand (numeric)
%       .filter_sz - nOrientations x nBands*nScalesPerBand (numeric)
%       .c1_scale - 1 x ? (numeric)
%       .c1_space - 1 x ? (numeric)
%       .patches - 1 x 8 (cell)
%       .patch_sz - 3 x 8 (numeric)
function [patchCache] = HMAXPatchCache (orientations, nBands)
    if ~exist('orientations', 'var') || isempty(orientations)
        orientations = [0,45,90,135]; % originally, this was the only choice
    end
    if ~exist('nBands', 'var') || isempty(nBands)
        nBands = 8; % originally, this was the only choice
    end
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
    patchCache.c1_scale = 1:nScalesPerBand:nScalesPerBand*nBands; % defining 8 scale bands with 2 scales each; there are 17 patches available in the patch cache
    patchCache.c1_space = 8:nScalesPerBand:8+nScalesPerBand*(nBands-1); % defining spatial pooling range for each scale band
    assert(nBands * nScalesPerBand == patchCache.c1_scale(end) + 1); % remember, last element in c1Scale is max scale - 1
    %   c1_scale: (for C1 units) a vector, defines the scale bands, a group of
    %       filter sizes over which a local max is taken to get C1 unit responses.
    %       ex. c1Scale = [1 k num_filters+1] means 2 bands, the first with
    %       filters(:,1:k-1) and the second with filters(:,k:num_filters).
    %       If N bands, make length(c1Scale) = N+1.
    %   c1_space: (for C1 units) a vector, defines the spatial pooling range of
    %       each scale band, ex. c1Space(i) = m means that each C1 unit response in
    %       band i is obtained by taking a max over a neighborhood of m x m S1 units.
    %       If N bands, make length(c1Space) = N.

    % for S2, C2
    load('universal_patch_set.mat', 'patches'); % mat file should be in path (found in ?/MatlabCommon/frontends/img_hmax/ folder)
    patchCache.patches = patches; % 1 x 8 (cell)
    patchCache.patch_sz = [2,4,6,8,10,12,14,16;2,4,6,8,10,12,14,16;4,4,4,4,4,4,4,4]; % same as load('universal_patch_set.mat', 'patchSizes'); patchSizes=patchSizes(1:3,:)
end