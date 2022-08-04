% deprecated (instead, see ml package)
function [data] = DistFromClustGMM(model, data)
    if strcmp(model.modelType, 'matlabbuiltin')
        data = posterior(model, data);
    elseif strcmp(model.modelType, 'em_matlabcentral')
        [~,data] = MixGaussPred(data', model); % data is now p - probability that item belongs to cluster
    else
        error('invalid model.modelType');
    end

    data = 1 - data;
end
