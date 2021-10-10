% Eli Bowen
% 6/24/2021
% computes a function iff it's cached output can't be found
% INPUTS:
%   func - function to compute
%   varargin - arguments to the function
function [varargout] = CachedCompute (func, varargin)
    validateattributes(func, {'function_handle'}, {'nonempty','scalar'});

    rng_state = rng();

    func_name = lower(func2str(func));

    t = tic();
    cache_file = GetCacheFile(varargin, func_name);
    if isfile(cache_file)
        load(cache_file, 'varargout');
        disp(['loading ',func_name,' took ',num2str(toc(t), '%.0f'),'s']);
    else
        [varargout{1:nargout}] = func(varargin{:});

        disp(['computing ',func_name,' took ',num2str(toc(t), '%.0f'),'s']);
        save(cache_file, 'varargout', '-v7.3');
    end

    rng(rng_state); % return to original random number generator state
end