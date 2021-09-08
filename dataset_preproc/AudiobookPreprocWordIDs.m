% Eli Bowen
% 5/25/2018
% build numeric word indices (translate words to numbers)
% INPUTS:
%   vocabFile - (char)
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocWordIDs (vocabFile, data)
    validateattributes(vocabFile, {'char'}, {'nonempty'});
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocWordIDs...');
    t = tic();

    if isfield(data, 'word')
        load(vocabFile, 'uniqueWords');
        uniqueWords = uniqueWords; % stupid matlab bullshit

        wordID = zeros(numel(data.word), 1);
        word = data.word;
        parfor i = 1:numel(wordID)
            temp = StringFind(uniqueWords, word{i}, true);
            if ~isempty(temp)
                wordID(i) = temp;
            end
        end
        data.word_id = wordID;
    end
    toc(t)
end