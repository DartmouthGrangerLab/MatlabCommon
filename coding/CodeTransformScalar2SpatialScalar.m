% Eli Bowen 8/12/2020
% takes an array of inputs, each of which is considered an independent scalar
% converts to a larger array of outputs, where each scalar is represented by a spatial code (Gaussian receptive fields arranged along the line)
% INPUTS:
%   data            - any dimensionality (numeric)
%   n_spatial_stops - scalar (numeric) - e.g. 5, number of stops to make along the scalar continuum (more means more specificity, more output dims)
%   meta            - OPTIONAL struct of metadata, each nonscalar field must be the same dimensionality as data
% RETURNS:
%   data - size(squeeze(data)) x n_spatial_stops numeric (same class as input)
%   meta - scalar (struct)
function [data,meta] = CodeTransformScalar2SpatialScalar(data, n_spatial_stops, meta)
    validateattributes(data, 'numeric', {'nonempty'});
    validateattributes(n_spatial_stops, 'numeric', {'nonempty','scalar','positive','integer'});
    assert(min(data(:)) >= 0 && max(data(:)) <= 1, 'input scalar code must be in range 0-->1');

    data = squeeze(data);
    n_used_dims = sum(size(data) > 1);
    if n_used_dims == 1
        data = data(:); % place vector along dim 1
    end

    d = cell(1, n_spatial_stops);
    for i = 1 : n_spatial_stops
        d{i} = normpdf(data, i/n_spatial_stops, i/(2*n_spatial_stops)) ./ normpdf(i/n_spatial_stops, i/n_spatial_stops, i/(2*n_spatial_stops));
        % note there is no detector for scalar=0, by preference
    end
    data = cat(n_used_dims + 1, d{:});

    if nargout() > 1
        if ~exist('meta', 'var') || isempty(meta)
            meta = struct();
        end

        r = [ones(1, n_used_dims),n_spatial_stops];
        fn = fieldnames(meta);
        for i = 1 : numel(fn)
            if numel(meta.(fn{i})) > 1
                temp = squeeze(meta.(fn{i}));
                if n_used_dims == 1
                    temp = temp(:);
                end
                meta.(fn{i}) = repmat(temp, r);
            end
        end

        % add new metadata
        meta.spatialStop = zeros(size(data));
        if n_used_dims == 1
            [~,meta.spatialStop(:)] = ind2sub(size(data), 1:numel(data));
        elseif n_used_dims == 2
            [~,~,meta.spatialStop(:)] = ind2sub(size(data), 1:numel(data));
        elseif n_used_dims == 3
            [~,~,~,meta.spatialStop(:)] = ind2sub(size(data), 1:numel(data));
        elseif n_used_dims == 4
            [~,~,~,~,meta.spatialStop(:)] = ind2sub(size(data), 1:numel(data));
        elseif n_used_dims == 5
            [~,~,~,~,~,meta.spatialStop(:)] = ind2sub(size(data), 1:numel(data));
        else
            error('havent bothered supporting > 5D inputs');
        end
    end
end