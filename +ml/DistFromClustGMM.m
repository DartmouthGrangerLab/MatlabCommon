% Eli Bowen 12/6/16
% performs an element-wise transform on each input in dist (changes distance to similarity via some function I really like at the moment)
% INPUTS
%   model - struct containing fields such as mu and sigma
%   data
% RETURNS
%   data - #signals x #prototypes distance matrix
function data = DistFromClustGMM(model, data)
    if strcmp(model.modelType, 'matlabbuiltin')
        data = posterior(model, data);
    elseif strcmp(model.modelType, 'em_matlabcentral')
        [~,data] = ml.MixGaussPred(data', model); % data is now p - probability that item belongs to cluster
    else
        error('invalid model.modelType');
    end

    data = 1 - data;
end
