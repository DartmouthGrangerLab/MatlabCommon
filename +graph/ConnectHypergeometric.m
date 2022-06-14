% Eli Bowen 1/12/2020
% creates a random hypergeometric connectivity profile
% INPUTS
%   n_src     - scalar (numeric) number of source items
%   n_dst     - scalar (numeric) numer of destination items
%   n_per_src - scalar (numeric) number of connections per source item (if you'd rather specify n_per_dst, just flip src and dst in your calling code!)
% RETURNS
%   srcIdx - 1 x n_connec (int-valued numeric) for each connection, the index of the source item (ranged 1 --> n_src)
%   dstIdx - 1 x n_connec (int-valued numeric) for each connection, the index of the destination item (ranged 1 --> n_dst)
function [srcIdx,dstIdx] = ConnectHypergeometric(n_src, n_dst, n_per_src)
    validateattributes(n_src, {'numeric'}, {'nonempty','scalar','positive','integer'}, 1);
    validateattributes(n_dst, {'numeric'}, {'nonempty','scalar','positive','integer'}, 2);
    validateattributes(n_per_src, {'numeric'}, {'nonempty','scalar','positive','integer'}, 3);

    n_connec = n_per_src * n_src;
    n_per_dst = max(1, ceil(n_connec / n_dst));
    assert(n_per_src <= n_dst); % can't connect to more than everyone
    assert(n_per_dst <= n_src); % can't connect to more than everyone

    % select N per source
    srcIdx = zeros(n_per_src, n_src);
    for i = 1 : n_src
        srcIdx(:,i) = i;
    end

    % select N per destination
    dstIdx = zeros(1, n_connec);
    for i = 1 : n_per_dst-1
        dstIdx((i-1)*n_dst+1:i*n_dst) = randperm(n_dst);
    end
    dstIdx((n_per_dst-1)*n_dst+1:end) = randperm(n_dst, numel(dstIdx((n_per_dst-1)*n_dst+1:end))); % get those last few
    dstIdx = dstIdx(randperm(n_connec)); % shuffle the bipartite pairings one more time

    srcIdx = srcIdx(:)';
    dstIdx = dstIdx(:)';
end