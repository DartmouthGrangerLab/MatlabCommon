% Eli Bowen 12/17/2021
% less error-prone version of matlab's errorbar()
% matlab's errorbar is annoying about x and y looking just right - this function pleases it
% also supports the additional name-value argument "alpha", for color transparency
% INPUTS
%   x
%   y
%   err
%   other arguments to matlab's errorbar()
% RETURNS
%   h - plot handle
% see also errorbar
function h = errorbar(x, y, err, varargin)
    validateattributes(x,   {'numeric','logical'}, {'nonempty'});
    validateattributes(y,   {'numeric','logical'}, {'nonempty'});
    validateattributes(err, {'numeric','logical'}, {'nonempty'});
    x   = double(x);
    y   = double(y);
    err = double(err);
    
    alpha = 1; % full opacity
    if any(strcmpi(varargin, 'alpha'))
        idx = find(strcmpi(varargin, 'alpha'));
        alpha = varargin{idx+1};
        validateattributes(alpha, 'numeric', {'nonempty','scalar','nonnegative'});
        varargin([idx,idx+1]) = [];
    end

    is_x_ndvec    = (sum(size(x) ~= 1) == 1);
    is_y_ndvec    = (sum(size(y) ~= 1) == 1);
    is_err_ndvec  = (sum(size(err) ~= 1) == 1);
    is_x_scalar   = (sum(size(x) ~= 1) == 0);
    is_y_scalar   = (sum(size(y) ~= 1) == 0);
    is_err_scalar = (sum(size(err) ~= 1) == 0);
    assert(is_err_ndvec == is_y_ndvec && is_err_scalar == is_y_scalar);
    if (~is_x_ndvec && ~is_x_scalar) || (~is_y_ndvec && ~is_y_scalar) || (is_x_scalar && is_y_scalar) % if either is an nd matrix, or both are scalars
        x   = squeeze(x);
        y   = squeeze(y);
        err = squeeze(err);
    elseif is_x_scalar && is_y_ndvec
        x   = repmat(x, 1, numel(y));
        y   = squeeze(y)';
        err = squeeze(err)';
    elseif is_x_ndvec && is_y_scalar
        x   = squeeze(x)';
        y   = repmat(y, 1, numel(x));
        err = repmat(err, 1, numel(x));
    elseif is_x_ndvec && is_y_ndvec
        x   = squeeze(x)';
        y   = squeeze(y)';
        err = squeeze(err)';
    else
        error('bug in code - all conditions should be handled');
    end

    h = errorbar(x, y, err, varargin{:});

    if alpha ~= 1
        set([h.Bar,h.Line], 'ColorType', 'truecoloralpha', 'ColorData', [h.Line.ColorData(1:3);255*alpha]); % undocumented matlab
    end
end