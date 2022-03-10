% Eli Bowen 8/12/2020
% takes an array of inputs, each of which is considered an independent scalar
% converts to a same-sized array of outputs, where each scalar is represented by a spiking rate code
% INPUTS:
%   data - any dimensionality (numeric)
% RETURNS:
%   data - logical same size as input data
function [data] = CodeTransformScalar2SpikeViaRate(data)
    validateattributes(data, 'numeric', {'nonempty'});
    assert(min(data(:)) >= 0 && max(data(:)) <= 1, 'input scalar code must be in range 0-->1');

    data = (rand(size(data)) < data);
end