% deprecated
function data = InjectNoise(data, n_desired_ones)
    validateattributes(data, {'logical'}, {}, 1);
    validateattributes(n_desired_ones, {'numeric'}, {'nonempty','scalar'}, 2);

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