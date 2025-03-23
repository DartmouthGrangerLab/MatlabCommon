% Eli Bowen 12/20/2021
% INPUTS
%   datasetStr - (char) '<datasetName>.<subset>', options:
%       'cifar10.trn'
%       'cifar10.tst'
%   path - OPTIONAL (char) directory in which to find the dataset file(s)
% RETURNS
%   img       - n_rows x n_cols x n_chan x n_images (double ranged 0 --> 1)
%   labelIdx  - 1 x n_images (numeric index)
%   uniqLabel - 1 x n_classes (cell array of chars)
function [img, labelIdx, uniqLabel, imgSz] = LoadCIFAR10(datasetStr, path)
    validateattributes(datasetStr, {'char'}, {'nonempty'}, 1);

    % parse datasetStr
    x = strsplit(datasetStr, '.');
    datasetName = x{1};
    subset = '';
    if numel(x) > 1
        subset = x{2};
    end

    if ~exist('path', 'var') || isempty(path)
        path = fullfile(ComputerProfile.DatasetDir(), 'cifar10', 'matlab');
    end

    img      = [];
    labelIdx = [];

    if strcmp(datasetName, 'cifar10')
        imgSz = [32, 32, 3];
        if strcmp(subset, 'trn')
            load(fullfile(path, 'data_batch_1.mat'), 'data', 'labels');
            data = data'; % for simplicity below, convert from n x d to d x n
            img = cat(4, img, permute(cat(4, reshape(data(1:1024,:), 32, 32, []), reshape(data(1025:2048,:), 32, 32, []), reshape(data(2049:3072,:), 32, 32, [])), [2,1,4,3]));
            labelIdx = cat(2, labelIdx, labels(:)' + 1); % numbers 0 through 9, plus 1
            load(fullfile(path, 'data_batch_2.mat'), 'data', 'labels');
            data = data'; % for simplicity below, convert from n x d to d x n
            img = cat(4, img, permute(cat(4, reshape(data(1:1024,:), 32, 32, []), reshape(data(1025:2048,:), 32, 32, []), reshape(data(2049:3072,:), 32, 32, [])), [2,1,4,3]));
            labelIdx = cat(2, labelIdx, labels(:)' + 1); % numbers 0 through 9, plus 1
            load(fullfile(path, 'data_batch_3.mat'), 'data', 'labels');
            data = data'; % for simplicity below, convert from n x d to d x n
            img = cat(4, img, permute(cat(4, reshape(data(1:1024,:), 32, 32, []), reshape(data(1025:2048,:), 32, 32, []), reshape(data(2049:3072,:), 32, 32, [])), [2,1,4,3]));
            labelIdx = cat(2, labelIdx, labels(:)' + 1); % numbers 0 through 9, plus 1
            load(fullfile(path, 'data_batch_4.mat'), 'data', 'labels');
            data = data'; % for simplicity below, convert from n x d to d x n
            img = cat(4, img, permute(cat(4, reshape(data(1:1024,:), 32, 32, []), reshape(data(1025:2048,:), 32, 32, []), reshape(data(2049:3072,:), 32, 32, [])), [2,1,4,3]));
            labelIdx = cat(2, labelIdx, labels(:)' + 1); % numbers 0 through 9, plus 1
            load(fullfile(path, 'data_batch_5.mat'), 'data', 'labels');
            data = data'; % for simplicity below, convert from n x d to d x n
            img = cat(4, img, permute(cat(4, reshape(data(1:1024,:), 32, 32, []), reshape(data(1025:2048,:), 32, 32, []), reshape(data(2049:3072,:), 32, 32, [])), [2,1,4,3]));
            labelIdx = cat(2, labelIdx, labels(:)' + 1); % numbers 0 through 9, plus 1
        elseif strcmp(subset, 'tst')
            load(fullfile(path, 'test_batch.mat'), 'data', 'labels');
            data = data'; % for simplicity below, convert from n x d to d x n
            img = permute(cat(4, reshape(data(1:1024,:), 32, 32, []), reshape(data(1025:2048,:), 32, 32, []), reshape(data(2049:3072,:), 32, 32, [])), [2,1,4,3]);
            labelIdx = labels(:)' + 1; % numbers 0 through 9, plus 1
        else
            error('unexpected subset');
        end
        load(fullfile(path, 'batches.meta.mat'), 'label_names'); % {'airplane','automobile','bird','cat','deer','dog','frog','horse','ship','truck'}
        uniqLabel = label_names';
    else
        error('unexpected dataset');
    end

    assert(isa(img, "uint8"));
    img = double(img) ./ 255;

    % validate
    assert(all(size(img) == [imgSz, size(img, 4)]));
    assert(min(labelIdx) > 0 && max(labelIdx <= numel(uniqLabel)));
end