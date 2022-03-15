% Eli bowen 12/17/2021
% less error-prone version of matlab's plot()
% matlab's plot is annoying about x and y looking just right - this function pleases it
% also supports the additional name-value argument "alpha", for color transparency
% INPUTS:
%   x
%   y
%   other arguments to matlab's plot()
% RETURNS:
%   h - plot handle
function [h] = Plot(x, y, varargin)
    validateattributes(x, {'numeric','logical'}, {'nonempty'});
    validateattributes(y, {'numeric','logical'}, {'nonempty'});
    x = double(x);
    y = double(y);

    alpha = 1; % full opacity
    if any(strcmpi(varargin, 'alpha'))
        idx = find(strcmpi(varargin, 'alpha'));
        alpha = varargin{idx+1};
        validateattributes(alpha, 'numeric', {'nonempty','scalar','nonnegative'});
        assert(alpha <= 1);
        varargin([idx,idx+1]) = [];
    end

    is_x_ndvec  = (sum(size(x) ~= 1) == 1);
    is_y_ndvec  = (sum(size(y) ~= 1) == 1);
    is_x_scalar = (sum(size(x) ~= 1) == 0);
    is_y_scalar = (sum(size(y) ~= 1) == 0);
    if (~is_x_ndvec && ~is_x_scalar) || (~is_y_ndvec && ~is_y_scalar) || (is_x_scalar && is_y_scalar) % if either is an nd matrix, or both are scalars
        x = squeeze(x);
        y = squeeze(y);
    elseif is_x_scalar && is_y_ndvec
        x = repmat(x, 1, numel(y));
        y = squeeze(y)';
    elseif is_x_ndvec && is_y_scalar
        x = squeeze(x)';
        y = repmat(y, 1, numel(x));
    elseif is_x_ndvec && is_y_ndvec
        x = squeeze(x)';
        y = squeeze(y)';
    else
        error('bug in code - all conditions should be handled');
    end

    h = plot(x, y, varargin{:});

    if alpha ~= 1
        h.Color(4) = alpha; % undocumented matlab
    end
end