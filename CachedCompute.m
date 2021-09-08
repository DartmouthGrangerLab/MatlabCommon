% Eli Bowen
% 6/24/2021
function [varargout] = CachedCompute (func, varargin)
    validateattributes(func, {'function_handle'}, {'nonempty','scalar'});
    
    rngState = rng();
    
    funcName = lower(func2str(func));
    
    t = tic();
    cacheFile = GetCacheFile(varargin, funcName);
    if isfile(cacheFile)
        load(cacheFile, 'varargout');
        disp(['loading ',funcName,' took ',num2str(toc(t), '%.0f'),'s']);
    else
        varargout{1:nargout} = func(varargin{:});
        
        disp(['computing ',funcName,' took ',num2str(toc(t), '%.0f'),'s']);
        save(cacheFile, 'varargout', '-v7.3');
    end
    
    rng(rngState); % return to original random number generator state
end