%Eli Bowen
%2/27/2020
%wrapper around the hmax library
function [c2,c1,bestBands,bestLocations,s2,s1] = HMAX (img)
    img = double(rgb2gray(img)); %image must be grayscale, double
    
    %% load the universal patch set
    load('universal_patch_set.mat', 'patches', 'patchSizes');
    nPatchSizes = size(patchSizes, 2);

    %% init S1 gabor filters
    orientations = [90,-45,0,45]; % 4 orientations for gabor filters
    RFsizes      = 7:2:39;        % receptive field sizes
    div          = 4:-.05:3.2;    % tuning parameters for the filters' "tightness"
    [filterSizes,filters,c1OL,~] = initGabor(orientations, RFsizes, div);

    %% init C1 parameters
    c1Scale = 1:2:18; % defining 8 scale bands
    c1Space = 8:2:22; % defining spatial pooling range for each scale band
    
    %% for each patch calculate unit responses
    [c2,c1,bestBands,bestLocations,s2,s1] = extractC2forCell(filters, filterSizes, c1Space, c1Scale, c1OL, patches, img, nPatchSizes, patchSizes(1:3,:));
end