% Eli Bowen
% 12/7/16
function [] = BuildTextVocabulary ()
    disp('VOCAB BUILDING...');

    sets{1} = 'Moby_Dick-Anthony_Heald';
    sets{2} = 'Moby_Dick-Norman_Dietz';
    sets{3} = 'Moby_Dick-Stewart_Wills';
    sets{4} = 'Harry_Potter_and_the_Sorcerers_Stone-English';
    sets{5} = 'Harry_Potter_and_the_Sorcerers_Stone-Japanese';
    sets{6} = 'Harry_Potter_and_the_Chamber_of_Secrets-English';
    sets{7} = 'Harry_Potter_and_the_Chamber_of_Secrets-Japanese';
    sets{8} = 'White_Fang_Unabridged-Flo_Gibson';
    sets{9} = 'White_Fang_Unabridged-Peter_Husmann';
    sets{10} = 'Wuthering_Heights_Unabridged-Charlton_Griffin';
    sets{11} = 'Wuthering_Heights_Unabridged-Emma_Messenger';

    sets{12} = 'Harry_Potter_and_the_Prisoner_of_Azkaban-English';
    sets{13} = 'Harry_Potter_and_the_Goblet_of_Fire-English';
    sets{14} = 'Harry_Potter_and_the_Order_of_the_Phoenix-English';
    sets{15} = 'Harry_Potter_and_the_Half_Blood_Prince-English';
    sets{16} = 'Harry_Potter_and_the_Deathly_Hallows-English';

    % never bothered with speechmatics for the below ones - should consider this in the future
    % sets{17} = 'Harry_Potter_and_the_Sorcerers_Stone-Japanese_Morio_Kazama';
    % sets{18} = 'Harry_Potter_and_the_Chamber_of_Secrets-Japanese_Morio_Kazama';
    % sets{19} = 'Harry_Potter_and_the_Prisoner_of_Azkaban-Japanese_Morio_Kazama';
    % sets{20} = 'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part1';
    % sets{21} = 'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part2';

    profile = ComputerProfile();

    uniqueWords = [];
    for i = 1:numel(sets)
        word = AudiobookPreprocWordsShort(fullfile(profile.dataset_dir, 'audio', sets{i}));
        uniqueWords = [uniqueWords;unique(word)];
    end
    uniqueWords = unique(uniqueWords);

    vocabDescription = 'generated from 16 audiobooks on 9.29.2017';
    save(fullfile(profile.dataset_dir, 'audio', 'vocabulary_9.29.2017.mat'), 'uniqueWords', 'vocabDescription', '-v7.3');

    disp('DONE');
end


function [word] = AudiobookPreprocWordsShort (path)
    validateattributes(path, {'char'}, {'nonempty'});

    [~,filePath] = CountFileType(path, 'wav', false);
    word = {};

    for i = 1:numel(filePath)
        disp(filePath{i});

        wordInfo = LoadSpeechmatics4Audio(filePath{i});

        if ~isempty(wordInfo)
            currWords = cell(numel(wordInfo), 1);
            for wordNum = 1:numel(wordInfo)
                currWords{wordNum} = lower(wordInfo{wordNum}.name);
            end
            word = [word;currWords];
        end
    end

    words2Remove = false(numel(word), 1);
    words2Remove(StringFind(word, '.', true)) = true;
    words2Remove(startsWith(word, '$')) = true;
    words2Remove(startsWith(word, '''')) = true;
    for i = 0:9
        words2Remove(startsWith(word, num2str(i))) = true; % starts with a digit
    end
    word(words2Remove) = [];
end