% Eli Bowen 5/2022
% fusion of matlab's built-in subplot or the subplot_tight 3rd party func, with hold on by default
% INPUTS
%   n_rows   - scalar (int-valued numeric)
%   n_cols   - scalar (int-valued numeric)
%   count    - scalar (int-valued numeric)
%   margin   - OPTIONAL
%   varargin - OPTIONAL other inputs to subplot_tight
% RETURNS
%   ax - axis handle
function ax = subplot(n_rows, n_cols, count, margin, varargin)
    if exist('margin', 'var') && ~isempty(margin)
        ax = subplot_tight(n_rows, n_cols, count, margin, varargin{:});
    else
        ax = subplot(n_rows, n_cols, count);
    end
    hold on
end