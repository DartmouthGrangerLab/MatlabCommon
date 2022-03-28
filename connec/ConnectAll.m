% Eli Bowen 3/20/2020
% given some set or population (e.g. of neurons), forms connections amonst them
% connect all neurons in srcMask to all neurons in dstMask
% INPUTS:
%   srcMsk - 1 x n (logical) mask on nrnlst (neurons which will project)
%   dstMsk - 1 x n (logical) mask on nrnlst (the destination neuron list)
% RETURNS:
%   src2HitIdx
%   dst2HitIdx
function [src2HitIdx,dst2HitIdx] = ConnectAll(srcMsk, dstMsk)
    validateattributes(srcMsk, {'logical'}, {'vector'}, 1);
    validateattributes(dstMsk, {'logical'}, {'vector'}, 2);
    assert(numel(srcMsk) == numel(dstMsk));
    assert(any(srcMsk) && any(dstMsk));
    srcMsk = srcMsk(:)'; % so we can assume it's 1 x n not n x 1
    dstMsk = dstMsk(:)'; % so we can assume it's 1 x n not n x 1

    srcIdx = find(srcMsk);
    dstIdx = find(dstMsk);
    n_src = numel(srcIdx);
    n_dst = numel(dstIdx);

    % select source and destination
    src2HitIdx = zeros(n_dst, n_src);
    dst2HitIdx = zeros(n_dst, n_src);
    for i = 1 : n_src
        src2HitIdx(:,i) = srcIdx(i);
        dst2HitIdx(:,i) = dstIdx;
    end
    src2HitIdx = src2HitIdx(:)';
    dst2HitIdx = dst2HitIdx(:)';
end