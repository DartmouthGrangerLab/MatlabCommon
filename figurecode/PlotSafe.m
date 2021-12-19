% Eli bowen
% 12/17/2021
% matlab's plot is annoying about x and y looking just right - this function pleases it
% INPUTS:
%   x
%   y
%   other arguments to matlab's plot()
% RETURNS:
%   h - plot handle
function [h] = PlotSafe (x, y, varargin)
    validateattributes(x, {'numeric','logical'}, {'nonempty'});
    validateattributes(y, {'numeric','logical'}, {'nonempty'});
    x = double(x);
    y = double(y);

    is_x_ndvec  = (sum(size(x) ~= 1) == 1);
    is_y_ndvec  = (sum(size(y) ~= 1) == 1);
    is_x_scalar = (sum(size(x) ~= 1) == 0);
    is_y_scalar = (sum(size(y) ~= 1) == 0);
    if (~is_x_ndvec && ~is_x_scalar) || (~is_y_ndvec && ~is_y_scalar) || (is_x_scalar && is_y_scalar) % if either is an nd matrix, or both are scalars
        h = plot(squeeze(x), squeeze(y), varargin{:});
    elseif is_x_scalar && is_y_ndvec
        h = plot(repmat(x, 1, numel(y)), squeeze(y)', varargin{:});
    elseif is_x_ndvec && is_y_scalar
        h = plot(squeeze(x)', repmat(y, 1, numel(x)), varargin{:});
    elseif is_x_ndvec && is_y_ndvec
        h = plot(squeeze(x)', squeeze(y)', varargin{:});
    else
        error('bug in code - all conditions should be handled');
    end
end