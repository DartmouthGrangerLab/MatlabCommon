%Eli Bowen
%5/25/2018
%build numeric word indices (translate words to numbers)
function [] = PreprocSpeechWordIDs (path, vocabFile)
    disp('PreprocSpeechWordIDs...');
    tic();
    if logical(exist(fullfile(path, 'words.mat'), 'file'))
        load(fullfile(path, 'words.mat'), 'words');

        load(vocabFile, 'uniqueWords');
        uniqueWords = uniqueWords; %stupid matlab bullshit

        wordIDs = zeros(numel(words), 1);
        parfor i = 1:numel(wordIDs)
            temp = StringFind(uniqueWords, words{i}, true);
            if ~isempty(temp)
                wordIDs(i) = temp;
            end
        end
    
        %% save
        save(fullfile(path, 'wordids.mat'), 'wordIDs', '-v7.3', '-nocompression');
    end
    toc
end