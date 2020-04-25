% Eli Bowen
% 5/25/2018
function [] = PreprocSpeechWords (path)
    disp('PreprocSpeechWords...');
    tic();
    
    listing = dir(fullfile(path, '*.wav'));
    timeOffset = 0;
    words = {};
    wordStartTimes = []; %in 32khz samples
    wordEndTimes = []; %in 32khz samples
    wordDurations = []; %in 32khz samples

    for i = 1:numel(listing)
        disp(listing(i).name);
        [y,Fs] = audioread(fullfile(path, listing(i).name));
        assert(Fs==32000);

        if logical(exist(fullfile(path, strrep(listing(i).name, '.wav', '.json')), 'file'))
            data = loadjson(fullfile(path, strrep(listing(i).name, '.wav', '.json')));
            wordInfo = data.words; %timepoints expected to be in units of SECONDS
        elseif logical(exist(fullfile(path, strrep(listing(i).name, '.wav', '.csv')), 'file'))
            fid = fopen(fullfile(path, strrep(listing(i).name, '.wav', '.csv')));
            data = textscan(fid, '%s,%f,%f', 'headerlines', 0);
            fclose(fid);
            wordInfo = cell(numel(data), 1);
            for j = 1:numel(wordInfo)
                wordInfo{j} = struct('name', data{j,1}, 'time', data{j,2}, 'duration', data{j,3}); %time and duration expected to be in units of SECONDS
            end
            error('^validate');
        else
            warning([fullfile(path, strrep(listing(i).name, '.wav', '.json')),' is missing!!!']);
        end
        
        if exist('wordInfo', 'var') && ~isempty(wordInfo)
            currWords = cell(numel(wordInfo), 1);
            currStartTimes = zeros(numel(wordInfo), 1);
            currDurations = zeros(numel(wordInfo), 1);
            currEndTimes = zeros(numel(wordInfo), 1);
            for wordNum = 1:numel(wordInfo)
                currWords{wordNum} = lower(wordInfo{wordNum}.name);
                currStartTimes(wordNum) = timeOffset + round(str2double(wordInfo{wordNum}.time) * 32000);
                currDurations(wordNum) = round(str2double(wordInfo{wordNum}.duration) * 32000);
                currEndTimes(wordNum) = currStartTimes(wordNum) + currDurations(wordNum);
            end
            words = [words;currWords];
            wordStartTimes = [wordStartTimes;currStartTimes];
            wordEndTimes = [wordEndTimes;currEndTimes];
            wordDurations = [wordDurations;currDurations];
        end
        
        timeOffset = timeOffset + numel(y);
        clearvars y;
    end
    
    words2Remove = false(numel(words), 1);
    words2Remove(StringFind(words, '.', true)) = true;
    words2Remove(startsWith(words, '$')) = true;
    words2Remove(startsWith(words, '''')) = true;
    for i = 0:9
        words2Remove(startsWith(words, num2str(i))) = true; %starts with a didgit
    end
    words(words2Remove) = [];
    wordStartTimes(words2Remove) = [];
    wordEndTimes(words2Remove) = [];
    wordDurations(words2Remove) = [];
    
    %% save
    if ~isempty(words)
        save(fullfile(path, 'words.mat'), 'words', 'wordStartTimes', 'wordEndTimes', 'wordDurations', '-v7.3', '-nocompression');
    end
    toc
end