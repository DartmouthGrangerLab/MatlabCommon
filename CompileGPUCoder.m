% Eli Bowen
% 11/2021
% INPUTS:
%   kernelPath - (char)
%   funcName - (char)
%   vars - (cell)
%   append - (char)
% RETURNS:
%   funcHandle - function handle for the compiled gpu kernel
function [funcHandle] = CompileGPUCoder (kernelPath, funcName, vars, append)
    validateattributes(kernelPath, 'char', {'nonempty'});
    validateattributes(funcName,   'char', {'nonempty'});
    validateattributes(vars,       'cell', {});
    validateattributes(append,     'char', {'nonempty'});

    t = tic();
    
    kernelFuncName = [funcName,'_',append,'_gpucoder'];

    args = cell(1, numel(vars));
    for j = 1 : numel(vars)
        args{j} = coder.typeof(vars{j}, size(vars{j}), false(1, numel(size(vars{j}))), 'Gpu', true); % false(1, *) means dimensions 1 and 2 are fixed-length (important for performance)
    end

    if ~isfolder(kernelPath) || ~IsDirInPath(kernelPath) % for speed
        mkdir(kernelPath);
        addpath(genpath(kernelPath));
    end

    gd = gpuDevice();
    cfg = coder.gpuConfig('mex');
    computeCapability = gd.ComputeCapability;
    maxSupportedComputeCapability = 8.0; % max supported GPU compute capability (varies by matlab version; not sure how to get this programmatically, 8.0 for 2021a)
    if str2double(computeCapability) > maxSupportedComputeCapability
        computeCapability = sprintf('%.1f', maxSupportedComputeCapability);
    end
    cfg.GpuConfig.ComputeCapability = computeCapability;
    codegen('-config', cfg, '-o', fullfile(kernelPath, kernelFuncName), funcName, '-args', args); % invoke gpu coder

    funcHandle = str2func(kernelFuncName);

    disp(['recompiling gpu coder for ',kernelFuncName,'(',strjoin(cellfun(@(X)X.ClassName, args, 'UniformOutput', false), ', '),')',' took ',num2str(toc(t)),' s']);
end