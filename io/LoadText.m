% Eli Bowen
% 11/19/2021
% INPUTS:
%   datasetName
% RETURNS:
%   text - (char)
function [text] = LoadText (datasetName)
    arguments
        datasetName (1,:) char
    end

    profile = ComputerProfile();

    if strcmp(datasetName, 'text_wikipedia')
        text = fileread(fullfile(profile.dataset_dir, 'text', 'wikipedia', 'enwiki-latest-pages-articles_preprocessed.txt'));
    elseif strcmp(datasetName, 'text_bookcorpus')
        text = fileread(fullfile(profile.dataset_dir, 'text', 'bookcorpus_homemade', 'bookcorpus_from_igor_brigadir', 'books_large_p1.txt'));
        text = [text,fileread(fullfile(profile.dataset_dir, 'text', 'bookcorpus_homemade', 'bookcorpus_from_igor_brigadir', 'books_large_p2.txt'))];
    else
        error('unexpected datasetName');
    end
end