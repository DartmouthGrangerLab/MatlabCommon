% Eli Bowen
% 11/19/2021
% INPUTS:
%   datasetName
% RETURNS:
%   text - (char) - comma separated list of datasets to load (must all be text)
function [text] = LoadText (datasetName)
    validateattributes(datasetName, 'char', {'nonempty','vector'});

    profile = ComputerProfile();
    datasetName = strsplit(datasetName, ',');

    %% load
    text = newline();
    for i = 1 : numel(datasetName)
        if strcmp(datasetName{i}, 'text_wikipedia')
            text = [text,newline(),fileread(fullfile(profile.dataset_dir, 'text', 'wikipedia', 'enwiki-latest-pages-articles_preprocessed.txt'))];
        elseif strcmp(datasetName{i}, 'text_bookcorpus')
            text = [text,newline(),fileread(fullfile(profile.dataset_dir, 'text', 'bookcorpus_homemade', 'bookcorpus_from_igor_brigadir', 'books_large_p1.txt'))];
            text = [text,newline(),fileread(fullfile(profile.dataset_dir, 'text', 'bookcorpus_homemade', 'bookcorpus_from_igor_brigadir', 'books_large_p2.txt'))];
        elseif strcmp(datasetName{i}, 'text_openwebtext')
            text = [text,newline(),fileread(fullfile(profile.dataset_dir, 'text', 'openwebtext', '???.txt'))];
            error('TODO: requires more extensive cleanup');
        else
            error('unexpected datasetName');
        end
    end
    text = [text,newline()];

    %% clean-up
    text = lower(text);
    text = regexprep(text, '\n\s*\n', newline()); % remove duplicate newlines (and any blank space between)
end