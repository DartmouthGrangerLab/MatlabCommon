% Eli Bowen 4/2022
% runs a function on one member of the parallel pool
% INPUTS:
%   func     - scalar (char or function_handle) function to compute
%   varargin - arguments to the function
% RETURNS:
%   f - scalar (Futures) can e.g. call wait(f, 'finished') to wait until this job is finished
% see also parfeval
function f = ParallelCompute(func, varargin)
    validateattributes(func, {'char','function_handle'}, {'nonempty'}, 1);
    if ischar(func)
        func = str2func(func);
    end

    rngState = rng();
    rngGpuState = gpurng();
    f = parfeval(@Helper, 0, func, rngState, rngGpuState, varargin{:});
end


function [] = Helper(func, rngState, rngGpuState, varargin)
    rng(rngState); % handle RNG so the par pool executes with the same rng as the main thread
    gpurng(rngGpuState);
    func(varargin{:});
end