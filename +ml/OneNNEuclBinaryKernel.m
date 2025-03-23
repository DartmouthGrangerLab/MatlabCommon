% Eli Bowen 11/4/2021
% for each observation, measure the sum of spikes claimed by each union
% append = GetMD5({size(trn_data),size(tst_data)}, 'array', 'hex');
% fh = CompileCoder('OneNNEuclBinaryKernel', {trn_data,tst_data}, false, 'cpu');
% fh = CompileCoder('OneNNEuclBinaryKernel', {gpuArray(single(trn_data),gpuArray(single(tst_data))}, true, 'gpu');
% INPUTS
%   trn_data - ...
%   tst_data - ...
% RETURNS
%   idx - ...
function idx = OneNNEuclBinaryKernel(trn_data, tst_data) %#codegen
    coder.gpu.kernelfun; % pragma that tells the gpu coder that this function can become a GPU kernel

    idx = NaN(size(tst_data, 2), 1);
    for i = 1 : size(tst_data, 2)
        [~,idx(i)] = min(sum(trn_data ~= tst_data(:,i), 1)); % implicit expansion
    end
end
