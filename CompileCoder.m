% Eli Bowen
% 11/2021
% compiles a matlab function to mex / mex+cuda
% INPUTS:
%   funcName - (char)
%   vars      - 1 x n_func_args (cell)
%   is_gpu  - scalar (logical) - if true, we're compiling a gpu cuda kernel, if false, we're compiling mex
%   append   - (char)
% RETURNS:
%   funcHandle - function handle for the compiled gpu kernel
function [funcHandle] = CompileCoder (funcName, vars, is_gpu, append)
    validateattributes(funcName, 'char',    {'nonempty'});
    validateattributes(vars,     'cell',    {});
    validateattributes(is_gpu,   'logical', {'nonempty','scalar'});
    validateattributes(append,   'char',    {'nonempty'});

    t = tic();

    %% parse function arguments
    args = cell(1, numel(vars));
    for j = 1 : numel(vars)
        if is_gpu
            if isscalar(vars{j})
                args{j} = vars{j};
            else
                args{j} = coder.typeof(vars{j}, size(vars{j}), false(1, numel(size(vars{j}))), 'Gpu', true); % false(1, *) means dimensions 1 and 2 are fixed-length (important for performance)
            end
        else
            args{j} = coder.typeof(vars{j}, size(vars{j}), false(1, numel(size(vars{j})))); % false(1, *) means dimensions 1 and 2 are fixed-length (important for performance)
        end
    end

    %% create coder config object
    if is_gpu
        cfg = coder.gpuConfig('mex');
        gd = gpuDevice();
        computeCapability = gd.ComputeCapability;
        maxSupportedComputeCapability = 8.0; % max supported GPU compute capability (varies by matlab version; not sure how to get this programmatically, 8.0 for 2021a)
        if str2double(computeCapability) > maxSupportedComputeCapability
            computeCapability = sprintf('%.1f', maxSupportedComputeCapability);
        end
        cfg.GpuConfig.ComputeCapability = computeCapability;
    else
        cfg = coder.config('mex');
    end

    %% create directory and add to path
    profile = ComputerProfile();
    kernelPath = fullfile(profile.cache_dir, 'compiledkernels');
    if ~isfolder(kernelPath) % for speed
        mkdir(kernelPath);
    end
    if ~IsDirInPath(kernelPath) % for speed
        addpath(genpath(kernelPath));
    end

    %% compile
    if is_gpu
        kernelFuncName = [funcName,'_',append,'_gpucdr'];
    else
        kernelFuncName = [funcName,'_',append,'_coder'];
    end
    
    codegen('-config', cfg, '-o', fullfile(kernelPath, kernelFuncName), funcName, '-args', args); % invoke coder

    funcHandle = str2func(kernelFuncName);

    argTxt = cell(1, numel(args));
    for i = 1 : numel(args)
        try
            argTxt{i} = args{i}.ClassName;
        catch
            argTxt{i} = class(args{i});
        end
    end
    disp(['recompiling code for ',kernelFuncName,'(',strjoin(argTxt, ', '),')',' took ',num2str(toc(t)),' s']);
end