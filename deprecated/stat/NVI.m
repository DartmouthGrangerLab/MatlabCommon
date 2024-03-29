% deprecated
function [z] = NVI (x, y)
    assert(numel(x) == numel(y));
    N = numel(x);
    x = reshape(x, 1, N);
    y = reshape(y, 1, N);

    l = min(min(x), min(y));
    x = x - l + 1;
    y = y - l + 1;
    k = max(max(x), max(y));

    idx = 1:N;
    Mx = sparse(idx, x, 1, N, k, N);
    My = sparse(idx, y, 1, N, k, N);
    Pxy = nonzeros(Mx' * My / N); %joint distribution of x and y
    Hxy = -dot(Pxy, log2(Pxy));

    Px = nonzeros(mean(Mx, 1));
    Py = nonzeros(mean(My, 1));

    %% entropy of Py and Px
    Hx = -dot(Px, log2(Px));
    Hy = -dot(Py, log2(Py));

    %% nvi
    z = 2 - (Hx+Hy) / Hxy;
    z = max(0, z);
end