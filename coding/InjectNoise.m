% Eli Bowen 2/2022
% INPUTS:
%   data             - d x n  (logical)
%   n_desired_spikes - scalar (int-valued numeric)
% RETURNS:
%   data - d x n (logical)
function [data] = InjectNoise(data, n_desired_spikes)
    validateattributes(data, 'logical', {});
    validateattributes(n_desired_spikes, 'numeric', {'nonempty','scalar'});

    data = full(data); % for speed
    randsPerImg = n_desired_spikes - sum(data, 1); % sum(trn.img, 1) = # spikes per image
    for i = 1 : size(data, 2) % for each observation
        notSpikingIdx = find(~data(:,i));
        data(notSpikingIdx(randperm(numel(notSpikingIdx), randsPerImg(i))),i) = true; % set random pixels to 1
    end
    data = sparse(data);
end