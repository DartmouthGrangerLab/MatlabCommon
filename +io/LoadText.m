% Eli Bowen 11/19/2021
% INPUTS
%   datasetName - (char)
%   path - OPTIONAL (char) dirctory in which to find the dataset file(s)
% RETURNS
%   text - (char) - comma separated list of datasets to load (must all be text)
function text = LoadText(datasetName, path)
    validateattributes(datasetName, {'char'}, {'nonempty','vector'}, 1);
    if ~exist('path', 'var') || isempty(path)
        path = fullfile(ComputerProfile.DatasetDir(), 'text');
    end

    datasetName = strsplit(datasetName, ',');

    %% load
    text = newline();
    for i = 1 : numel(datasetName)
        if strcmp(datasetName{i}, 'text_text8')
            text = [text,newline(),io.UnzipText(fullfile(path, 'text8.txt.zip'))];
        elseif strcmp(datasetName{i}, 'text_wikipedia')
            text = [text,newline(),io.UnzipText(fullfile(path, 'wikipedia', 'enwiki-latest-pages-articles_preprocessed.txt.zip'))];
        elseif strcmp(datasetName{i}, 'text_bookcorpus')
            text = [text,newline(),io.UnzipText(fullfile(path, 'bookcorpus_homemade', 'bookcorpus_from_igor_brigadir', 'books_large_p1.txt.zip'))];
            text = [text,newline(),io.UnzipText(fullfile(path, 'bookcorpus_homemade', 'bookcorpus_from_igor_brigadir', 'books_large_p2.txt.zip'))];
        elseif strcmp(datasetName{i}, 'text_openwebtext')
            text = [text,newline(),io.UnzipText(fullfile(path, 'openwebtext', '???.txt.zip'))];
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