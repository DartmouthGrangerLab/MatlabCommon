% Eli Bowen
% 12/30/16
% INPUTS:
%   data - an official dataset struct
%   set2
function [data] = AudiobookMergeDatasets (data, set2)
    % implicitly creating a structuctuct
    
    %% scalars
    if isfield(data, 'descriptor')
        assert(isfield(set2, 'descriptor'), 'either both or neither set must contain this field');
        data.descriptor = [data.descriptor,'_',set2.descriptor];
    end
    if isfield(data, 'sample_rate')
        assert(isfield(set2, 'sample_rate'), 'either both or neither set must contain this field');
        assert(data.sample_rate == set2.sample_rate);
    end
    if isfield(data, 'duration')
        duration = data.duration; % for use down below
        assert(isfield(set2, 'duration'), 'either both or neither set must contain this field');
        data.duration = data.duration + set2.duration; % in (32khz) samples
    end
    
    %% one item per (32khz) sample
    if isfield(data, 'audio')
        assert(isfield(set2, 'audio'), 'either both or neither set must contain this field');
        data.audio = [data.audio;set2.audio];
    end
    if isfield(data, 'silence')
        assert(isfield(set2, 'silence'), 'either both or neither set must contain this field');
        data.silence = [data.silence;set2.silence];
    end
    
    %% one item per spectrogram column
    if isfield(data, 'data')
        assert(isfield(set2, 'data'), 'either both or neither set must contain this field');
%         specSize = size(data.spectrogram_in, 1); % needed later
        data.data = [data.data;set2.data];
    end
    
    %% one item per word
    if isfield(data, 'word_audio')
        assert(isfield(set2, 'word_audio'), 'either both or neither set must contain this field');
        data.word_audio = [data.word_audio;set2.word_audio];
    end
    if isfield(data, 'wordSpectrograms')
        assert(isfield(set2, 'wordSpectrograms'), 'either both or neither set must contain this field');
        data.wordSpectrograms = [data.wordSpectrograms;set2.wordSpectrograms];
    end
    if isfield(data, 'word')
        assert(isfield(set2, 'word'), 'either both or neither set must contain this field');
        data.word = [data.word;set2.word];
        if isfield(data, 'word_start_time')
            assert(isfield(data, 'word_end_time') && isfield(set2, 'word_start_time') && isfield(set2, 'word_end_time'), 'either both or neither set must contain both wordStartTimes and wordEndTimes');
            data.word_start_time = [data.word_start_time;set2.word_start_time+duration];
            data.word_end_time = [data.word_end_time;set2.word_end_time+duration];
        end
        
        fields = {'word_id','word_duration','word_phonetic','word_landmarks','word_landmarks_speechmark','word_landmarks_montreal','word_montrealforcedalignment','word_fave'};
        for i = 1:numel(fields)
            assert((isfield(data, fields{i}) && isfield(set2, fields{i})) || (~isfield(data, fields{i}) && ~isfield(set2, fields{i})), ['either both or neither set must contain the field [',fields{i},']']);
            if isfield(data, fields{i})
                data.(fields{i}) = [data.(fields{i});set2.(fields{i})];
            end
        end
    end
    
    %% one item per phoneme
    if isfield(data, 'phoneme')
        assert(isfield(set2, 'phoneme'), 'either both or neither set must contain phonemes');
        data.phoneme = [data.phoneme;set2.phoneme];
        if isfield(data, 'phoneme_start_time')
            assert(isfield(data, 'phoneme_end_time') && isfield(set2, 'phoneme_start_time') && isfield(set2, 'phoneme_end_time'), 'either both or neither set must contain both phonemeStartTimes and phonemeEndTimes');
            data.phoneme_start_time = [data.phoneme_start_time;set2.phoneme_start_time+duration];
            data.phoneme_end_time = [data.phoneme_end_time;set2.phoneme_end_time+duration];
        end
        
        fields = {'phoneme_duration'};
        for i = 1:numel(fields)
            assert((isfield(data, fields{i}) && isfield(set2, fields{i})) || (~isfield(data, fields{i}) && ~isfield(set2, fields{i})), ['either both or neither set must contain the field [',fields{i},']']);
            if isfield(data, fields{i})
                data.(fields{i}) = [data.(fields{i});set2.(fields{i})];
            end
        end
    end
end