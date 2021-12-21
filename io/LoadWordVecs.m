% Eli Bowen
% 11/19/2021
% INPUTS:
%   datasetName
% RETURNS:
%   word - 1 x n_words (cell array of chars)
%   vec  - n_dims x n_words (numeric)
function [word,vec] = LoadWordVecs(datasetName)
    validateattributes(datasetName, 'char', {'nonempty'});

    directory = fullfile(ComputerProfile.DatasetDir(), 'wordvec');

    %% load
    if strcmp(datasetName, 'wordvec_glove6')
        text = fileread(fullfile(directory, 'glove', 'glove.6B.300d.txt'));
    elseif strcmp(datasetName, 'wordvec_glove42')
        text = fileread(fullfile(directory, 'glove', 'glove.42B.300d.txt'));
    elseif strcmp(datasetName, 'wordvec_glove840')
        text = fileread(fullfile(directory, 'glove', 'glove.840B.300d.txt')); %% 11 GB loaded
    elseif strcmp(datasetName, 'wordvec_smalldensebin_glove6')
        text = fileread(fullfile(directory, 'small_dense_binary', 'glove.6B.300d_with_header_binarized_trulybinary.vec'));
        error('parsing code will be wrong for this - need to bring in parsing code from the small_dense_binary folder');
        % vector building code fails (produces all vectors all 1's) on glove.42B and glove.840B
    elseif strcmp(datasetName, 'wordvec_largesparsebin_glove6x10')
        text = fileread(fullfile(directory, 'large_sparse_binary', 'glove.6B.300d_sparsifiedx10.txt')); % 6 GB loaded; 10% nonzero
    elseif strcmp(datasetName, 'wordvec_largesparsebin_glove6x20')
        text = fileread(fullfile(directory, 'large_sparse_binary', 'glove.6B.300d_sparsifiedx20.txt'));
        error('untested');
    elseif strcmp(datasetName, 'wordvec_largesparsebin_glove840x20')
        text = fileread(fullfile(directory, 'large_sparse_binary', 'glove.840B.300d_sparsifiedx20.txt'));
        error('untested');
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
    if startsWith(datasetName, 'wordvec_glove')
        % n/a
    elseif startsWith(datasetName, 'wordvec_smalldensebin')
        error('TODO: remove header');
    elseif startsWith(datasetName, 'wordvec_largesparsebin')
        vec(end,:) = [];
%         vec = vec ./ max(vec(:)); % put it in a nice range of 0-->1
        vec = (vec > 0);
    else
        error('unexpected datasetName');
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