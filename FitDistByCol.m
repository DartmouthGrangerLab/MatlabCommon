% Eli Bowen 1/19/2022
% call fitdist independently for every column of the data matrix
% matlab's fitdist by grouping variable is embarassingly slow
% call makedist(distName, '<paramname>', params.___(i)) to reconstruct a distribution object
%   e.g. pd = makedist('Poisson', 'lambda', params.lambda(i));
% INPUTS:
%   data        - n_pts x n
%   distName    - (char) second param to matlab's fitdist()
%   other arguments to matlab's fitdist()
% RETURNS:
%   params - scalar (struct) - each field is a 1 x n set of distribution parameters
function [params] = FitDistByCol(data, distName, varargin)
    n = size(data, 2);

    params = struct();
    pd = makedist(distName);
    for i = 1 : numel(pd.ParameterNames)
        params.(pd.ParameterNames{i}) = zeros(1, n);
    end

    for i = 1 : n
        pd = fitdist(data(:,i), distName, varargin{:});
        for j = 1 : numel(pd.ParameterNames)
            params.(pd.ParameterNames{j})(i) = pd.(pd.ParameterNames{j});
        end
    end
end