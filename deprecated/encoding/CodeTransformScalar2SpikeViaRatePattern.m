% Eli Bowen 8/12/2020
% takes an array of inputs, each of which is considered an independent scalar
% converts to a same-sized array of outputs, where each scalar is represented by a spiking rate code
% INPUTS:
%   data - any dimensionality (numeric)
%   meta - OPTIONAL struct of metadata, each nonscalar field must be the same dimensionality as data
% RETURNS:
%   data - size(squeeze(data)) x patternDuration logical
%   meta - scalar (struct)
function [data,meta] = CodeTransformScalar2SpikeViaRatePattern(data, meta)
    validateattributes(data, {'numeric'}, {'nonempty'}, 1);
    assert(min(data(:)) >= 0 && max(data(:)) <= 1, 'input scalar code must be in range 0-->1');

    data = squeeze(data);
    n_used_dims = sum(size(data) > 1);
    if n_used_dims == 1
        data = data(:); % place vector along dim 1
    end

    patternDuration = 5; % in gammas

    % i think below is what we want
%     tf = (val > 0.5);
%     idx = ((0:(obj.numNrn-1)) .* patternDuration + obj.nTimesIdentical) .* tf;
%     %TODO: is below or above faster? are they identical?
%     idx = (find(tf)-1) .* patternDuration + obj.nTimesIdentical(tf);
%     data = false(1, obj.numNrn);
%     data(idx) = true;
%     assert(size(data, 2) == obj.numNrn);
    % actually i think below is even faster
%     obj.dataCache = false(obj.numNrn/patternDuration, patternDuration); % place in constructor
%     obj.dataCache(:) = false;
%     obj.dataCache(:,obj.nTimesIdentical) = val;
%     data = obj.dataCache(:)';

    if nargout() > 1
        if ~exist('meta', 'var') || isempty(meta)
            meta = struct();
        end
        
        r = [ones(1, n_used_dims),n_spatial_stops];
        fields = fieldnames(meta);
        for i = 1 : numel(fields)
            if numel(meta.(fields{i})) > 1
                temp = squeeze(meta.(fields{i}));
                if n_used_dims == 1
                    temp = temp(:);
                end
                meta.(fields{i}) = repmat(temp, r);
            end
        end
        
        % add new metadata
        error('TODO: add nTimesIdentical to metadata');
    end
end