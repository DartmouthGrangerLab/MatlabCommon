function [output] = TestGPUCoder_PutOnGPU(input) %#codegen
    
    
    coder.gpu.kernelfun; % tells the gpu coder that this function should become a GPU kernel
    output = input;
end