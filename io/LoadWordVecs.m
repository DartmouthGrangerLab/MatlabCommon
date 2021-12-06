% Eli Bowen
% 11/19/2021
% RETURNS:
%   word - 1 x n_words (cell array of chars)
%   vec  - n_dims x n_words (numeric)
function [word,vec] = LoadWordVecs (datasetName)
    arguments
        datasetName (1,:) char
    end

    %% load
    profile = ComputerProfile();
    if strcmp(datasetName, 'wordvec_glove6')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'glove', 'glove.6B.300d.txt'));
    elseif strcmp(datasetName, 'wordvec_glove42')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'glove', 'glove.42B.300d.txt'));
    elseif strcmp(datasetName, 'wordvec_glove840')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'glove', 'glove.840B.300d.txt')); %% 11 GB loaded
    elseif strcmp(datasetName, 'wordvec_small_dense_bin_glove6')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'small_dense_binary', 'glove.6B.300d_with_header_binarized_trulybinary.vec'));
        error('TODO: remove header');
        % vector building code fails (produces all vectors all 1's) on glove.42B and glove.840B
    elseif strcmp(datasetName, 'wordvec_large_sparse_bin_glove6')
        text = fileread(fullfile(profile.dataset_dir, 'word_vectors', 'large_sparse_binary', 'glove.6B.300d_sparsified.txt'));
        error('TODO: remove header?');
        % vector building code fails (crashes) on glove.840B
    else
        error('unexpected datasetName');
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