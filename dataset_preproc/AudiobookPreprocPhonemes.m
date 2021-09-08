% Eli Bowen
% 5/25/2018
% INPUTS:
%   path - (char) - data folder
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocPhonemes (path, data)
    validateattributes(path, {'char'}, {'nonempty'});
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocPhonemes...');
    t = tic();

    listing = dir(fullfile(path, '*.wav'));
    timeOffset = 0;
    phoneme          = {};
    phonemeStartTime = []; % in units of samples
    phonemeEndTime   = []; % in units of samples
    phonemeDuration  = []; % in units of samples
    for i = 1:numel(listing)
        disp(listing(i).name);

        [y,fs] = audioread(fullfile(path, listing(i).name));
        assert(fs == data.sample_rate);

        if logical(exist(fullfile(path, 'sphinxphonemes', strrep(listing(i).name, '.wav', '.txt')), 'file'))
            fid = fopen(fullfile(path, 'sphinxphonemes', strrep(listing(i).name, '.wav', '.txt')));
            text = textscan(fid, '%s', 'headerlines', 0, 'Delimiter', '\n');
            text = text{1}; % stupid matlab
            fclose(fid);
            phonemeInfo = cell(numel(text), 1);
            for j = 1:numel(phonemeInfo)
                line = strsplit(text{j}); % splits on whitespace
                if numel(line) == 4 && str2double(line{4}) == 1 % if more than 4 this is one of those annoying lines sphinx inserts
                    phonemeInfo{j} = struct('name', lower(line{1}), 'time', str2double(line{2}) * data.sample_rate, 'duration', (str2double(line{3})-str2double(line{2})) * data.sample_rate);
                end
            end
            phonemeInfo(cellfun('isempty', phonemeInfo)) = [];
        end
        
        if exist('phonemeInfo', 'var') && ~isempty(phonemeInfo)
            currPhonemes   = cell(numel(phonemeInfo), 1);
            currStartTimes = zeros(numel(phonemeInfo), 1);
            currDurations  = zeros(numel(phonemeInfo), 1);
            for wordNum = 1:numel(phonemeInfo)
                currPhonemes{wordNum}   = phonemeInfo{wordNum}.name;
                currStartTimes(wordNum) = timeOffset + phonemeInfo{wordNum}.time;
                currDurations(wordNum)  = phonemeInfo{wordNum}.duration;
            end
            currEndTimes = currStartTimes + currDurations;
            phoneme          = [phoneme;currPhonemes];
            phonemeStartTime = [phonemeStartTime;currStartTimes];
            phonemeEndTime   = [phonemeEndTime;currEndTimes];
            phonemeDuration  = [phonemeDuration;currDurations];
        end
        
        timeOffset = timeOffset + numel(y);
        clearvars y;
    end

    phonemes2Remove = false(1, numel(phoneme));
    phonemes2Remove(StringFind(phoneme, 'sil', true))   = true; % silence isn't a phoneme bro
    phonemes2Remove(StringFind(phoneme, '+nsn+', true)) = true; % noise
    phonemes2Remove(StringFind(phoneme, '+spn+', true)) = true; % speechy noise
    phoneme(phonemes2Remove)          = [];
    phonemeStartTime(phonemes2Remove) = [];
    phonemeEndTime(phonemes2Remove)   = [];
    phonemeDuration(phonemes2Remove)  = [];

    %% save
    if ~isempty(phoneme)
        data.phoneme            = phoneme;
        data.phoneme_start_time = phonemeStartTime;
        data.phoneme_end_time   = phonemeEndTime;
        data.phoneme_duration   = phonemeDuration;
    end
    toc(t)
end