% Eli Bowen 2/2022
% inject noise into each datapoint to reach the desired number of trues / ones per column
% INPUTS:
%   data           - d x n (logical)
%   n_desired_ones - scalar (int-valued numeric)
% RETURNS:
%   data - d x n (logical)
function [data] = InjectNoise(data, n_desired_ones)
    validateattributes(data, 'logical', {});
    validateattributes(n_desired_ones, 'numeric', {'nonempty','scalar'});

    is_sparse = issparse(data);
    data = full(data); % for speed

    randsPerImg = n_desired_ones - sum(data, 1); % sum(trn.img, 1) = # spikes per image
    for i = 1 : size(data, 2) % for each observation
        notSpikingIdx = find(~data(:,i));
        if numel(notSpikingIdx) <= randsPerImg(i)
            data(:,i) = true; % set all to true
        elseif randsPerImg(i) > 0
            data(notSpikingIdx(randperm(numel(notSpikingIdx), randsPerImg(i))),i) = true; % set random dimensions to 1
        end
    end

    if is_sparse
        data = sparse(data);
    end
end