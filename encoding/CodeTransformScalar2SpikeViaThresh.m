% Eli Bowen 8/12/2020
% takes an array of inputs, each of which is considered an independent scalar
% converts to a same-sized array of outputs, where each scalar is represented by a spike if it's above threshold
% INPUTS:
%   data   - any dimensionality (numeric)
%   thresh - scalar (numeric between 0 and 1)
% RETURNS:
%   data - logical same size as input data
function [data] = CodeTransformScalar2SpikeViaThresh(data, thresh)
    validateattributes(data, {'numeric'}, {'nonempty'}, 1);
    validateattributes(thresh, {'numeric'}, {'nonempty','scalar','positive'}, 2);
    assert(min(data(:)) >= 0 && max(data(:)) <= 1, 'input scalar code must be in range 0-->1');

    data = (data > thresh);
end