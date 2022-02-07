function [output] = TestGPUCoder(w, efferentPSP, srcIdx) %#codegen
    % below are optional - used by gpu coder to help it make assumptions (useful for performance I think)
%     assert(isa(U,'int32'));          % used by gpu coder to precompute datatype
    assert(size(w, 1) == 1);           % assume this is a vector
    assert(size(efferentPSP, 1) == 1); % assume this is a vector
    assert(size(srcIdx, 1) == 1);      % assume this is a vector
    assert(isreal(w));                 % assume values will be real
    assert(isreal(efferentPSP));       % assume values will be real
    assert(isreal(srcIdx));            % assume values will be real
%     assert(size(w, 2) < ???);           % specify maximum size
%     assert(size(efferentPSP, 2) < ???); % specify maximum size
%     assert(size(srcIdx, 2) < ???);      % specify maximum size

%     if ~exist('TestGPUCoder_kernelhalf')
%         gd = gpuDevice();
%         cfg = coder.gpuConfig('mex');
%         cfg.GpuConfig.ComputeCapability = gd.ComputeCapability; % may not be necessary
%         
%         ARGS = cell(1, 3);
%         ARGS{1} = coder.typeof(half(0), [1,1000], [false,true], 'Gpu', true); % doesn't run
%         ARGS{2} = coder.typeof(half(0), [1,1000], [false,true], 'Gpu', true);
%         ARGS{3} = coder.typeof(half(0), [1,1000], [false,true], 'Gpu', true);
% %         ARGS{1} = coder.typeof(single(0), [1,1000], [false,true], 'Gpu', true); % runs
% %         ARGS{2} = coder.typeof(single(0), [1,1000], [false,true], 'Gpu', true);
% %         ARGS{3} = coder.typeof(single(0), [1,1000], [false,true], 'Gpu', true);
%         codegen -config cfg -o TestGPUCoder_kernelhalf TestGPUCoder -args ARGS; % invoke gpu coder
        % with below, we can init the kernel to take half precision as input, but above makes sure the input is already on the gpu - TODO: test which is better
%         codegen -config cfg -o TestGPUCoder_kernelhalf TestGPUCoder -args {w,efferentPSP,srcIdx}; % invoke gpu coder
%     end

    ver = version('-release'); % returns a string like '2020a'
    if str2double(ver(1:4)) < 2020 || str2double(gd.ComputeCapability) < 5.3
        % can't use half precision with gpu coder
    end
    flintmax('single') % largest consecutive integer represented by single precision float (~16 million)
    %^TODO: check for this when converting type of an *Idx variable
    %TODO: check relative performance of using integers vs floats for indexing
    intmax('int32') % largest 32-bit int (~2 billion)

%     w = single(rand(1, 1000));
%     efferentPSP = single(rand(1, 1000));
%     srcIdx = single(randi(1000, 1, 1000));
%     output = TestGPUCoder(w, efferentPSP, srcIdx);

    % check gpu install for codegen support
%     envCfg = coder.gpuEnvConfig('host');
%     envCfg.BasicCodegen = 1;
%     envCfg.Quiet = 1;
%     coder.checkGpuInstall(envCfg);

    coder.gpu.kernelfun; % pragma that tells the gpu coder that this function should become a GPU kernel
%     output = w .* efferentPSP(srcIdx,1)';
    output = w .* efferentPSP(srcIdx);
end