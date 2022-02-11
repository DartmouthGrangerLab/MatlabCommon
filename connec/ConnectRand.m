% Eli Bowen
% 1/12/2020
% given some set or population (e.g. of neurons), forms connections amonst them
% INPUTS:
%   srcMsk  - 1 x n (logical) mask on nrnlst (neurons which will project)
%   dstMsk  - 1 x n (logical) mask on nrnlst (the destination neuron list)
%   percent - scalar (numeric) % of random synapses per input and/or per output
%   method  - (char) 'srcchoose', 'dstchoose', or 'hypergeom'
% RETURNS:
%   src2HitIdx
%   dst2HitIdx
function [src2HitIdx,dst2HitIdx] = ConnectRand(srcMsk, dstMsk, percent, method)
    validateattributes(srcMsk,  'logical', {'vector'});
    validateattributes(dstMsk,  'logical', {'vector'});
    validateattributes(percent, 'double',  {'nonempty','scalar','positive'});
    validateattributes(method,  'char',    {'nonempty','vector'});
    assert(numel(srcMsk) == numel(dstMsk));
    assert(any(srcMsk) && any(dstMsk));
    srcMsk = srcMsk(:)'; % so we can assume it's 1 x n not n x 1
    dstMsk = dstMsk(:)'; % so we can assume it's 1 x n not n x 1

    srcIdx = find(srcMsk);
    dstIdx = find(dstMsk);
    n_src = numel(srcIdx);
    n_dst = numel(dstIdx);
    n_per_src = round(percent * sum(dstMsk));
    n_new_syn = n_per_src * n_src;

    if strcmp(method, 'srcchoose')
        % select n per source
        src2HitIdx = zeros(n_per_src, n_src);
        for i = 1 : n_src
            src2HitIdx(:,i) = srcIdx(i);
        end

        % select destinations
        dst2HitIdx = dstIdx(randi(n_dst, 1, n_new_syn));
    elseif strcmp(method, 'dstchoose')
        error('not yet implemented');
    elseif strcmp(method, 'hypergeom')
        [src2HitIdx,dst2HitIdx] = ConnectHypergeometric(n_src, n_dst, n_per_src);
        src2HitIdx = srcIdx(src2HitIdx); % convert idx from 1:n_src to items from srcIdx
        dst2HitIdx = dstIdx(dst2HitIdx); % convert idx from 1:n_dst to items from dstIdx
    else
        error('unknown method');
    end

    src2HitIdx = src2HitIdx(:)';
    dst2HitIdx = dst2HitIdx(:)';
end