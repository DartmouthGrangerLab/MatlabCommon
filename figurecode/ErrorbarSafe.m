% Eli bowen
% 12/17/2021
% matlab's errorbar is annoying about x and y looking just right - this function pleases it
% INPUTS:
%   x
%   y
%   err
%   other arguments to matlab's errorbar()
% RETURNS:
%   h - plot handle
function [h] = ErrorbarSafe (x, y, err, varargin)
    validateattributes(x, {'numeric','logical'}, {'nonempty'});
    validateattributes(y, {'numeric','logical'}, {'nonempty'});
    validateattributes(err, {'numeric','logical'}, {'nonempty'});
    x   = double(x);
    y   = double(y);
    err = double(err);

    is_x_ndvec    = (sum(size(x) ~= 1) == 1);
    is_y_ndvec    = (sum(size(y) ~= 1) == 1);
    is_err_ndvec  = (sum(size(err) ~= 1) == 1);
    is_x_scalar   = (sum(size(x) ~= 1) == 0);
    is_y_scalar   = (sum(size(y) ~= 1) == 0);
    is_err_scalar = (sum(size(err) ~= 1) == 0);
    assert(is_err_ndvec == is_y_ndvec && is_err_scalar == is_y_scalar);
    if (~is_x_ndvec && ~is_x_scalar) || (~is_y_ndvec && ~is_y_scalar) || (is_x_scalar && is_y_scalar) % if either is an nd matrix, or both are scalars
        h = errorbar(squeeze(x), squeeze(y), squeeze(err), varargin{:});
    elseif is_x_scalar && is_y_ndvec
        h = errorbar(repmat(x, 1, numel(y)), squeeze(y)', squeeze(err)', varargin{:});
    elseif is_x_ndvec && is_y_scalar
        h = errorbar(squeeze(x)', repmat(y, 1, numel(x)), repmat(err, 1, numel(x)), varargin{:});
    elseif is_x_ndvec && is_y_ndvec
        h = errorbar(squeeze(x)', squeeze(y)', squeeze(err)', varargin{:});
    else
        error('bug in code - all conditions should be handled');
    end
end