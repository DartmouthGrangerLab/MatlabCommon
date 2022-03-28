% WMEAN(X,W,DIM) takes the weighted mean along the dimension DIM of X. 
% For vectors, WMEAN(X,W) is the weighted mean value of the elements in X using non-negative weights W.
% For matrices, WMEAN(X,W) is a row vector containing the weighted mean value of each column.
% For N-D arrays, WMEAN(X,W) is the weighted mean value of the elements along the first non-singleton dimension of X.
% Each element of X requires a corresponding weight, and hence the size  of W must match that of X.
% INPUTS:
%   class support for inputs X and W: float: double, single
% RETURNS:
%   y
% USAGE:
%   x = rand(5,2);
%   w = rand(5,2);
%   wmean(x, w)
% downloaded from https://www.mathworks.com/matlabcentral/fileexchange/14416-wmean?s_tid=srchtitle
% modified by Eli Bowen only for readability and consistency
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

    y = sum(w .* x, dim) ./ sum(w, dim);
end