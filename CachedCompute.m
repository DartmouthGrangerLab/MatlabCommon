% Eli Bowen 6/24/2021
% computes a function iff it's cached output can't be found
% INPUTS:
%   func     - (char or function_handle) function to compute
%   varargin - arguments to the function
% RETURNS:
%   whatever func would return
function [varargout] = CachedCompute(func, varargin)
    validateattributes(func, {'char','function_handle'}, {'nonempty'}, 1);
    if ischar(func)
        func = str2func(func);
    end
    funcName = lower(func2str(func));

    rngState = rng();

    t = tic();
    file = CacheFile(varargin, funcName, 'cachedcompute');
    if isfile(file)
        load(file, 'varargout');
        if toc(t) > 1
            disp([funcName,' cache hit took ',num2str(toc(t), '%.0f'),' s']);
        end
    else
        [varargout{1:nargout}] = func(varargin{:});
        if toc(t) > 1
            disp(['computing ',funcName,' took ',num2str(toc(t), '%.0f'),' s']);
            save(file, 'varargout', '-v7.3'); % don't bother caching if it's super fast
        end
    end

    rng(rngState); % return to original random number generator state
end