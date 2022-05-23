% Eli Bowen 5/20/2021
% given some set or population (e.g. of neurons), forms connections amonst them
% connect all neurons in srcMask to all neurons in dstMask
% INPUTS:
%   srcMsk           - 1 x n (logical) mask on nrnlst (neurons which will project)
%   dstMsk           - 1 x n (logical) mask on nrnlst (the destination neuron list)
%   posR             - 1 x n (numeric)
%   posC             - 1 x n (numeric)
%   radius           - scalar (numeric)
%   is_dst_fractured - scalar (logical)
% RETURNS:
%   src2HitIdx
%   dst2HitIdx
function [src2HitIdx,dst2HitIdx] = ConnectAllInRadius(srcMsk, dstMsk, posR, posC, radius, is_dst_fractured)
    validateattributes(srcMsk,           {'logical'}, {'vector'}, 1);
    validateattributes(dstMsk,           {'logical'}, {'vector'}, 2);
    validateattributes(posR,             {'numeric'}, {'vector'}, 3);
    validateattributes(posC,             {'numeric'}, {'vector'}, 4);
    validateattributes(radius,           {'double'},  {'nonempty','scalar','positive'}, 5);
    validateattributes(is_dst_fractured, {'logical'}, {'nonempty','scalar'}, 6);
    assert(numel(srcMsk) == numel(dstMsk) && numel(srcMsk) == numel(posR) && numel(srcMsk) == numel(posC));
    assert(any(srcMsk) && any(dstMsk));
    srcMsk = srcMsk(:)'; % so we can assume it's 1 x n not n x 1
    dstMsk = dstMsk(:)'; % so we can assume it's 1 x n not n x 1

    srcIdx = find(srcMsk);
    dstIdx = find(dstMsk);
    n_src = numel(srcIdx);
    n_dst = numel(dstIdx);

    % compute pairwise dists from each source (circle center) to each destination
    dists = pdist2([posR(srcMsk)',posC(srcMsk)'], [posR(dstMsk)',posC(dstMsk)'], 'euclidean');
    % pdists and pdf should be n_src x n_dst

    % select source and destination
    [src2HitIdx,dst2HitIdx] = find(dists < radius);
    if is_dst_fractured
        dstIdx = dstIdx(randperm(n_dst));
    end
    src2HitIdx = srcIdx(src2HitIdx);
    dst2HitIdx = dstIdx(dst2HitIdx);
    src2HitIdx = src2HitIdx(:)';
    dst2HitIdx = dst2HitIdx(:)';
end