% deprecated - see stat.wmean
function y = wmean(x, w, dim)
    validateattributes(x, {'numeric'}, {}, 1);
    validateattributes(w, {'numeric'}, {}, 2);
    assert(isequal(size(x), size(w)), 'inputs x and w must be the same size');
    assert(all(w(:) >= 0), 'all weights, w, must be non-negative');
    assert(~all(w(:) == 0), 'at least one weight must be non-zero');
    if nargin == 2
        % determine which dimension sum will use
        dim = find(size(x) ~= 1, 1, 'first'); % tweaked by EB for efficiency
        if isempty(dim)
            dim = 1;
        end
    end

    y = stat.wmean(x, w, dim);
end