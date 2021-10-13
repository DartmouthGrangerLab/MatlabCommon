% INPUTS:
%   c1: see C1.m (was called c1BandImg)
%   imgSz - size of the input image
%   c1Space: see C1.m
%   c1Scale: see C1.m
%   filterSz: see C1.m
%   linearPatches: nRows*nCols*nOrientations x nPatches (numeric), the prototypes (patches) used in the extraction of s2
%       each patch of size nRows x nCols x nOrientations is stored as a row in linearPatches
%   patchSz: 1 x 3 (numeric) - [nRows,nCols,nOrientations], describing the size of each patch in linearPatches
%   IGNOREPARTIALS: scalar (logical) if true, "partial" activations will be
%       ignored, and only filter and patch activations completely on the image
%       will be used. If false, all S2 activations are used.
%   ALLS2C1PRUNE: scalar, see windowedPatchDistance.m
%   ORIENTATIONS2C1PRUNE: scalar, see windowedPatchDistance.m
%
% RETURNS:
%     s2: a cell array [nPatches 1], contains the S2 responses for img
%     c2: a matrix [nPatches 1], contains the C2 responses for img
%
% See also C1 (C1.m)
% modified by Eli Bowen only for clarity and to no longer call C1 within this function (call C1 first) and to switch return value order for efficiency
function [s2,c2,bestBands,bestLocations] = C2 (c1, imgSz, c1Space, c1Scale, filterSz, linearPatches, patchSz, IGNOREPARTIALS, ALLS2C1PRUNE, ORIENTATIONS2C1PRUNE)
    nBands = numel(c1);
    nPatchRows = patchSz(1);
    nPatchCols = patchSz(2);
    nPatches = size(linearPatches, 2);

    % build s2:
    s2 = cell(nBands, nPatches);
    for iPatch = 1:nPatches
        squarePatch = reshape(linearPatches(:,iPatch), patchSz);
        for b = 1:nBands
            s2{b,iPatch} = windowedPatchDistance(c1{b}, squarePatch, ALLS2C1PRUNE, ORIENTATIONS2C1PRUNE);  
        end
    end

    % build c2:
    if nargout() > 1
        c2 = inf(1, nPatches);
        bestBands = zeros(1, nPatches);
        bestLocations = zeros(nPatches, 2);
        for iPatch = 1:nPatches
            for b = 1:nBands
                [nRows,nCols] = size(s2{b,iPatch});
                if IGNOREPARTIALS
                    ignorePartials = inf(nRows, nCols);
                    poolRange = c1Space(b);
                    maxFilterRows = 1:poolRange/2:imgSz(1);
                    maxFilterCols = 1:poolRange/2:imgSz(2);
                    invalidS1Pre = ceil(filterSz(1,c1Scale(b)) / 2);
                    invalidS1Post = floor(filterSz(1,c1Scale(b)) / 2);
                    rMin = ceil(nPatchRows/2) + sum(ismember(maxFilterRows,1:invalidS1Pre));
                    rMax = nRows - floor(nPatchRows/2) - sum(ismember(maxFilterRows,(imgSz(1)-(invalidS1Post+poolRange-1)):imgSz(1))); 
                    cMin = ceil(nPatchCols/2) + sum(ismember(maxFilterCols,1:invalidS1Pre));
                    cMax = nCols - floor(nPatchCols/2) - sum(ismember(maxFilterCols,(imgSz(2)-(invalidS1Post+poolRange-1)):imgSz(2)));
                    if rMin < rMax && cMin < cMax
                        ignorePartials(rMin:rMax,cMin:cMax) = s2{b,iPatch}(rMin:rMax,cMin:cMax);
                    end
                    [minValue,minIdx] = min(ignorePartials(:));
                else
                    [minValue,minIdx] = min(s2{b,iPatch}(:));
                end
                if minValue < c2(iPatch)
                    c2(iPatch) = minValue;
                    bestBands(iPatch) = b;
                    [bestLocations(iPatch,1),bestLocations(iPatch,2)] = ind2sub([nRows,nCols], minIdx);
                end
            end
        end
    end
end