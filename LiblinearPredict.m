% Eli Bowen
% 10/1/2021
% wrapper designed to simplify and remove the chance of errors when calling liblinear's predict() function
% designed to work with liblinear-multicore version 2.43-2
% INPUTS:
%   model - struct generated by TrainLiblinear()
%   label - 1 x n_datapts (numeric)
%   data - n_datapts x ? (numeric or logical)
% RETURNS:
%   predLabel - 1 x n_datapts
%   acc - scalar (numeric) - accuracy ranged 0 --> 1
%   score - n_datapts x n_classes
%   mse - scalar (numeric) - mean squared error
%   sqcorr - scalar (numeric) - squared correlation coefficient
function [predLabel,acc,score,mse,sqcorr] = LiblinearPredict (model, label, data)
    validateattributes(model, {'struct'}, {'nonempty','scalar'});
    validateattributes(label, {'numeric'}, {'nonempty','vector','positive','integer'});
    validateattributes(data, {'double','logical'}, {'nonempty','2d','nonnan','nrows',numel(label)});
    if islogical(data)
        data = double(data);
    end
    assert(~isa(data, 'gpuArray')); % liblinear doesn't have gpu support

    [predLabel,temp,temp2] = predict_liblinear(label, sparse(data), model, '-q'); % temp = [accuracy out of 100, MSE, squared correlation coeff]
    acc    = temp(1) / 100; % convert to range 0-->1 to be more like most matlab accuracy measures
    mse    = temp(2);
    sqcorr = temp(3);
    
    if numel(unique(label)) == 2
        score = NaN(numel(temp2), 2);
        score(:,1) = temp2;
        % WARNING: when liblinear does 2-class classification, score is n_pts x 1 instead of n_pts x n_classes
    else
        score = temp2;
    end
end