% Eli Bowen
% 5/25/2018
% INPUTS:
%   dictPath - (char)
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocPhoneticSpellings (dictPath, data)
    validateattributes(dictPath, {'char'}, {'nonempty'});
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocPhoneticSpellings...');
    t = tic();

    if isfield(data, 'word')
        uniqueWords = unique(data.word);

        %% load arpabet
        [arpabetDictEnglish,arpabetDictPhonetic] = LoadArpabet(dictPath);

        %% identify dataset words present in phonetic dictionary
        uniqueWordsPhonetic = cell(numel(uniqueWords), 1);
        words2Delete = false(numel(uniqueWords), 1);
        parfor i = 1:numel(uniqueWords)
            dictIdx = StringFind(arpabetDictEnglish, uniqueWords{i}, true);
            if numel(dictIdx) == 1
                uniqueWordsPhonetic{i} = arpabetDictPhonetic{dictIdx};
            else
                words2Delete(i) = true;
            end
        end
        uniqueWords(words2Delete) = [];
        uniqueWordsPhonetic(words2Delete) = [];

        %% add phonetic spellings to the dataset
        if numel(uniqueWords) > 0
            data.word_phonetic = cell(size(data.word));
            for i = 1:numel(uniqueWords)
                data.word_phonetic(StringFind(data.word, uniqueWords{i}, true)) = {uniqueWordsPhonetic{i}};
            end
        end
    end
    toc(t) % 636 sec
end