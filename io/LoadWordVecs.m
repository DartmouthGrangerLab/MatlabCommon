% Eli Bowen 11/19/2021
% INPUTS:
%   name - (char) name of dataset e.g. 'wordvec_glove6' (see code for options)
%   path - OPTIONAL (char) directory in which to find the dataset file(s)
% RETURNS:
%   word - 1 x n_words (cell array of chars)
%   vec  - n_dims x n_words (numeric)
function [word,vec] = LoadWordVecs(name, path)
    validateattributes(name, 'char', {'nonempty'}, 1);

    if ~exist('path', 'var') || isempty(path)
        path = fullfile(ComputerProfile.DatasetDir(), 'wordvec');
    end

    %% load
    if strcmp(name, 'wordvec_glove6')
        text = UnzipText(fullfile(path, 'glove', 'glove.6B.300d.txt.zip'));
    elseif strcmp(name, 'wordvec_glove42')
        text = UnzipText(fullfile(path, 'glove', 'glove.42B.300d.txt.zip'));
    elseif strcmp(name, 'wordvec_glove840')
        text = UnzipText(fullfile(path, 'glove', 'glove.840B.300d.txt.zip')); % 11 GB loaded
    elseif strcmp(name, 'wordvec_smalldensebin_glove6')
        text = UnzipText(fullfile(path, 'small_dense_binary', 'glove.6B.300d_with_header_binarized_trulybinary.vec.zip'));
        error('parsing code will be wrong for this - need to bring in parsing code from the small_dense_binary folder');
        % vector building code fails (produces all vectors all 1's) on glove.42B and glove.840B
    elseif strcmp(name, 'wordvec_largesparsebin_glove6x10')
        text = UnzipText(fullfile(path, 'large_sparse_binary', 'glove.6B.300d_sparsifiedx10.txt.zip')); % 6 GB loaded; 10% nonzero
    elseif strcmp(name, 'wordvec_largesparsebin_glove6x20')
        text = UnzipText(fullfile(path, 'large_sparse_binary', 'glove.6B.300d_sparsifiedx20.txt.zip'));
        error('untested');
    elseif strcmp(name, 'wordvec_largesparsebin_glove840x20')
        text = UnzipText(fullfile(path, 'large_sparse_binary', 'glove.840B.300d_sparsifiedx20.txt.zip'));
        error('untested');
    else
        error('unexpected name');
    end

    %% parse
    text = strsplit(text, '\n');
    dims = cellfun(@(x)sum(x==' '), text); % plus 1 (for the last element) minus 1 (for word);
    if dims(end) == 0 % trailing new-line
        text = text(1:end-1);
        dims = dims(1:end-1);
    end
    n_words = numel(text);
    n_dims = unique(dims);
    assert(numel(n_dims) == 1);
    word = cell(1, n_words);
    vec = zeros(n_dims, n_words);
    for i = 1 : n_words
        line = strsplit(text{i}, ' ');
        word{i} = line{1};
        vec(:,i) = str2double(line(2:end));
    end
    if startsWith(name, 'wordvec_glove')
        % n/a
    elseif startsWith(name, 'wordvec_smalldensebin')
        error('TODO: remove header');
    elseif startsWith(name, 'wordvec_largesparsebin')
        vec(end,:) = [];
%         vec = vec ./ max(vec(:)); % put it in a nice range of 0-->1
        vec = (vec > 0);
    else
        error('unexpected name');
    end

    %% clean up
    word = lower(word);
    [~,idx] = sort(word);
    word = word(idx);
    vec = vec(:,idx);

    %% remove vectors for words we don't like
    %TODO: consider doing in the future if we want
%     counts2 = cellfun(@(x)sum(x==char(160)), text);
%     for j = find(counts2 > 0)
%         disp(text{j});
%     end

    %% validate
    assert(numel(word) == numel(unique(word)));
end