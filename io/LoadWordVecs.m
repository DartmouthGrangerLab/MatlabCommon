% Eli Bowen
% 11/19/2021
% INPUTS:
%   datasetName
% RETURNS:
%   words - 1 x n_words (cell array of chars)
%   vecs  - n_dims x n_words (numeric)
function [words,vecs] = LoadWordVecs (datasetName)
    arguments
        datasetName (1,:) char
    end

    %% load
    profile = ComputerProfile();
    if strcmp(datasetName, 'wordvec_glove')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'glove', 'glove.840B.300d.txt')); %% 11 GB loaded
    elseif strcmp(datasetName, 'wordvec_small_dense_bin')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'small_dense_binary', 'binary_vectors_trulybinary.vec'));
        %TODO: remove header
        error('TODO');
    elseif strcmp(datasetName, 'wordvec_large_sparse_bin')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'large_sparse_binary', 'glove.840B.300d_sparsified.txt'));
        %TODO: remove header
        error('TODO');
    else
        error('unexpected datasetName');
    end

    %% parse
    text = strsplit(text, '\n');
    n_words = numel(text);
    n_dims = unique(cellfun(@(x)sum(x==' '), text)) - 1;
    assert(numel(n_dims) == 1);
    words = cell(1, n_words);
    vecs = zeros(n_dims, n_words);
    for i = 1 : n_words
        line = strsplit(text{i}, ' ');
        words{i} = line{1};
        vecs(:,i) = str2double(line(2:end));
    end

    %% remove vectors for words we don't like
    %TODO: consider doing in the future if we want
%     counts2 = cellfun(@(x)sum(x==char(160)), text);
%     for j = find(counts2 > 0)
%         disp(text{j});
%     end
end