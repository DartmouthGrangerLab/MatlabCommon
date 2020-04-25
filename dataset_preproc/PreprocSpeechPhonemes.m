% Eli Bowen
% 5/25/2018
function [] = PreprocSpeechPhonemes (path)
    disp('PreprocSpeechPhonemes...');
    t = tic();
    listing = dir(fullfile(path, '*.wav'));
    timeOffset = 0;
    phonemes = {};
    phonemeStartTimes = []; %in 32khz samples
    phonemeEndTimes = []; %in 32khz samples
    phonemeDurations = []; %in 32khz samples
    for i = 1:numel(listing)
        disp(listing(i).name);
        [y,Fs] = audioread(fullfile(path, listing(i).name));
        assert(Fs==32000);
        
        if logical(exist(fullfile(path, 'sphinxphonemes', strrep(listing(i).name, '.wav', '.txt')), 'file'))
            fid = fopen(fullfile(path, 'sphinxphonemes', strrep(listing(i).name, '.wav', '.txt')));
            data = textscan(fid, '%s', 'headerlines', 0, 'Delimiter', '\n');
            data = data{1}; %stupid matlab
            fclose(fid);
            phonemeInfo = cell(numel(data), 1);
            for j = 1:numel(phonemeInfo)
                line = strsplit(data{j}); %splits on whitespace
                if numel(line) == 4 && str2double(line{4}) == 1 %if more than 4 this is one of those annoying lines sphinx inserts
                    phonemeInfo{j} = struct('name', lower(line{1}), 'time', str2double(line{2}) * 32000, 'duration', (str2double(line{3})-str2double(line{2})) * 32000);
                end
            end
            phonemeInfo(cellfun('isempty', phonemeInfo)) = [];
        end
        
        if exist('phonemeInfo', 'var') && ~isempty(phonemeInfo)
            currPhonemes = cell(numel(phonemeInfo), 1);
            currStartTimes = zeros(numel(phonemeInfo), 1);
            currDurations = zeros(numel(phonemeInfo), 1);
            for wordNum = 1:numel(phonemeInfo)
                currPhonemes{wordNum} = phonemeInfo{wordNum}.name;
                currStartTimes(wordNum) = timeOffset + phonemeInfo{wordNum}.time;
                currDurations(wordNum) = phonemeInfo{wordNum}.duration;
            end
            currEndTimes = currStartTimes + currDurations;
            phonemes = [phonemes;currPhonemes];
            phonemeStartTimes = [phonemeStartTimes;currStartTimes];
            phonemeEndTimes = [phonemeEndTimes;currEndTimes];
            phonemeDurations = [phonemeDurations;currDurations];
        end
        
        timeOffset = timeOffset + numel(y);
        clearvars y;
    end
    
    phonemes2Remove = false(1, numel(phonemes));
    phonemes2Remove(StringFind(phonemes, 'sil', true)) = true; %silence isn't a phoneme bro
    phonemes2Remove(StringFind(phonemes, '+nsn+', true)) = true; %noise
    phonemes2Remove(StringFind(phonemes, '+spn+', true)) = true; %speechy noise
    phonemes(phonemes2Remove) = [];
    phonemeStartTimes(phonemes2Remove) = [];
    phonemeEndTimes(phonemes2Remove) = [];
    phonemeDurations(phonemes2Remove) = [];
    
    %% save
    if ~isempty(phonemes)
        save(fullfile(path, 'phonemes.mat'), 'phonemes', 'phonemeStartTimes', 'phonemeEndTimes', 'phonemeDurations', '-v7.3', '-nocompression');
    end
    toc(t)
end