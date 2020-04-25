%Eli Bowen
%5/25/2018
function [] = PreprocSpeechPhoneticSpellings (path, dictPath)
    disp('PreprocSpeechPhoneticSpellings...');
    tic;
    if logical(exist(fullfile(path, 'words.mat'), 'file'))
        load(fullfile(path, 'words.mat'), 'words');
        uniqueWords = unique(words);

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

        if numel(uniqueWords) > 0
            %% add phonetic spellings to the dataset
            wordsPhonetic = cell(size(words));
            for i = 1:numel(uniqueWords)
                wordsPhonetic(StringFind(words, uniqueWords{i}, true)) = {uniqueWordsPhonetic{i}};
            end

            %% save
            save(fullfile(path, 'wordsphonetic.mat'), 'wordsPhonetic', '-v7.3', '-nocompression');
        end
    end
    toc %636sec
end