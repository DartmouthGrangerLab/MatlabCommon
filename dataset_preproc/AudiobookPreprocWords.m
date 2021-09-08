% Eli Bowen
% 5/25/2018
% INPUTS:
%   path - (char) - data folder
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocWords (path, data)
    validateattributes(path, {'char'}, {'nonempty'});
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocWords...');
    t = tic();

    [~,filePath] = CountFileType(path, 'wav', false);
    timeOffset = 0;
    word          = {};
    wordStartTime = []; % in units of samples
    wordEndTime   = []; % in units of samples
    wordDuration  = []; % in units of samples

    for i = 1:numel(filePath)
        disp(filePath{i});

        [y,fs] = audioread(filePath{i});
        assert(fs == data.sample_rate);

        wordInfo = LoadSpeechmatics4Audio(filePath{i});

        if ~isempty(wordInfo)
            currWords      = cell(numel(wordInfo), 1);
            currStartTimes = zeros(numel(wordInfo), 1);
            currDurations  = zeros(numel(wordInfo), 1);
            currEndTimes   = zeros(numel(wordInfo), 1);
            for wordNum = 1:numel(wordInfo)
                currWords{wordNum} = lower(wordInfo{wordNum}.name);
                currStartTimes(wordNum) = timeOffset + round(str2double(wordInfo{wordNum}.time) * data.sample_rate);
                currDurations(wordNum) = round(str2double(wordInfo{wordNum}.duration) * data.sample_rate);
                currEndTimes(wordNum) = currStartTimes(wordNum) + currDurations(wordNum);
            end
            word          = [word;currWords];
            wordStartTime = [wordStartTime;currStartTimes];
            wordEndTime   = [wordEndTime;currEndTimes];
            wordDuration  = [wordDuration;currDurations];
        end
        
        timeOffset = timeOffset + numel(y);
    end
    
    words2Remove = false(numel(word), 1);
    words2Remove(StringFind(word, '.', true)) = true;
    words2Remove(startsWith(word, '$')) = true;
    words2Remove(startsWith(word, '''')) = true;
    for i = 0:9
        words2Remove(startsWith(word, num2str(i))) = true; % starts with a digit
    end
    word(words2Remove)          = [];
    wordStartTime(words2Remove) = [];
    wordEndTime(words2Remove)   = [];
    wordDuration(words2Remove)  = [];
    
    %% save
    if ~isempty(word)
        data.word            = word;
        data.word_start_time = wordStartTime;
        data.word_end_time   = wordEndTime;
        data.word_duration   = wordDuration;
    end
    toc(t)
end