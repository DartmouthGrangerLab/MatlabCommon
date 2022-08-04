% deprecated (instead, see ml package)
function [predLabel,acc,score,mse,sqcorr] = LiblinearPredict(model, label, data)
    validateattributes(model, {'struct'},  {'nonempty','scalar'}, 1);
    validateattributes(label, {'numeric'}, {'nonempty','vector','positive','integer'}, 2);
    validateattributes(data, {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',numel(label)}, 3);
    assert(~isa(data, 'gpuArray'), 'liblinear doesn''t have gpu support');
    
    label = label(:); % required orientation...
    if islogical(data)
        % data is already at its limits (0 --> 1)
    else
        data = data - model.norm_min;  % scale tst by trn mins
        data = data ./ model.norm_max; % scale tst by trn maxes
    end
    data = double(data);
    data = sparse([data,ones(numel(label), 1)]); % sparse required by the alg, performance is often poor without a col of ones at the end
    
    [predLabel,temp,temp2] = predict_liblinear(label, data, model, '-q'); % temp = [accuracy out of 100, MSE, squared correlation coeff]
    acc    = temp(1) / 100; % convert to range 0-->1 to be more like most matlab accuracy measures
    mse    = temp(2);
    sqcorr = temp(3);
    
    if numel(unique(label)) == 2
        score = NaN(numel(temp2), 2);
        score(:,1) = temp2;
%         score = (score ./ max(abs(score))) ./ 2 + 0.5; % convert score to be more like matlab's built-in classifier scores
        % WARNING: when liblinear does 2-class classification, score is n_pts x 1 instead of n_pts x n_classes
    else
        score = temp2;
    end
end