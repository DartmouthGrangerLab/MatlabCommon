% Eli Bowen 12/17/2021
% less error-prone version of matlab's plot()
% matlab's plot is annoying about x and y looking just right - this function pleases it
% also supports the additional name-value argument "alpha", for color transparency
% also supports color = 'redblue' (gradient red to blue)
% INPUTS:
%   x
%   y
%   other arguments to matlab's plot()
% RETURNS:
%   h - plot handle
function h = Plot(x, y, varargin)
    validateattributes(x, {'numeric','logical'}, {'nonempty'}, 1);
    validateattributes(y, {'numeric','logical'}, {'nonempty'}, 2);
    x = double(x);
    y = double(y);

    alpha = 1; % full opacity
    idx = find(strcmpi(varargin, 'alpha'));
    if ~isempty(idx)
        alpha = varargin{idx+1};
        validateattributes(alpha, {'numeric'}, {'nonempty','nonnegative'});
        assert(all(alpha <= 1));
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

    idx = find(strcmpi(varargin, 'color'));
    if ~isempty(idx) && strcmpi(varargin{idx+1}, 'redblue')
        varargin([idx,idx+1]) = [];
        h = plot(x, y, varargin{:});
        set(h.Edge, 'ColorBinding', 'interpolated', 'ColorData', redblue());
    else
        h = plot(x, y, varargin{:});
    end

    if ~all(alpha == 1)
        if isscalar(alpha)
            alpha = repmat(alpha, numel(h), 1);
        end
        for i = 1 : numel(h) % for each line we've plotted
            h(i).Color(4) = alpha(i); % undocumented matlab
        end
    end
end