% Eli Bowen 5/2022
% like matlab's built-in insertShape(), but:
%   for shape = 'line', supports:
%       faster render times
%       color = 'redblue'
%       alpha parameter for transparency (TODO)
% INPUTS
%   img
%   shape - (char)
%   position
%   varargin
% RETURNS
%   img - n_rows x n_cols x 3
% see also insertShape
function img = insertShape(img, shape, position, varargin)
    alpha = 1; % full opacity
    idx = find(strcmpi(varargin, 'alpha'));
    if ~isempty(idx)
        alpha = varargin{idx+1};
        validateattributes(alpha, {'numeric'}, {'nonempty','nonnegative'});
        assert(alpha <= 1);
        varargin([idx,idx+1]) = [];
    end

    if strcmpi(shape, 'line')
        assert(all(alpha == 1), 'TODO');
        idx = find(strcmpi(varargin, 'color'));
        if ~isempty(idx) && strcmp(varargin{idx+1}, 'redblue')
            varargin([idx,idx+1]) = [];
            cmap = redblue(11); % 10 color stops
            cmap(6,:) = []; % excluding the white middle part
            for i = 1 : size(cmap, 1)
                temp = position; % n_lines x 4 (numeric)
                temp(:,1) = position(:,1) + (position(:,3) - position(:,1)) * (i-1) / size(cmap, 1);
                temp(:,2) = position(:,2) + (position(:,4) - position(:,2)) * (i-1) / size(cmap, 1);
                temp(:,3) = position(:,1) + (position(:,3) - position(:,1)) * i / size(cmap, 1);
                temp(:,4) = position(:,2) + (position(:,4) - position(:,2)) * i / size(cmap, 1);
                img = insertShape(img, shape, temp, 'Color', cmap(i,:), varargin{:});
            end
        else
            img = insertShape(img, shape, position, varargin{:});
        end
    else
        assert(all(alpha == 1), 'alpha only supported for shape == line');
        img = insertShape(img, shape, position, varargin{:});
    end
%     img = insertShape(img, 'Line', line(idx,:), 'Color', color, 'SmoothEdges', false, 'LineWidth', lineWidth);
end