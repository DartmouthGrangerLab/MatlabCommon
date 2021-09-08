% Eli Bowen
% 11/13/17
% removes all silent timepoints (PURE zeros only)
% INPUTS:
%   data - an official dataset struct
function [data] = AudiobookCropSilence (data)
    assert(isfield(data, 'silence'));
    
    if sum(data.silence) == 0
        return;
    end
    
    disp(['cropsilence is removing ',num2str(100*sum(data.silence)/numel(data.silence)),'% of the data...']);
    tic;
    
    %% one item per 32khz sample
    if isfield(data, 'audio')
%         data.audio(data.silence) = [];
        data.audio = data.audio(~data.silence); % this uses less memory for some bullshit reason
    end
    
    %% one item per spectrogram column
    if isfield(data, 'data')
        error('you need to call CropSilence before adding spectrograms to the dataset');
    end
    
    %% one item per word
    if isfield(data, 'word_start_time')
        assert(isfield(data, 'word_end_time') && isfield(data, 'word'));
        
        % remove completely silent words
        words2Remove = false(numel(data.word_start_time), 1); % like 1%
        for i = 1:numel(data.word_start_time)
            if all(data.silence(data.word_start_time(i):data.word_end_time(i)))
                words2Remove(i) = true;
            end
        end
        
        fields = {'word','word_start_time','word_end_time','word_audio','word_spectrogram','word_duration','word_id','word_phonetic','word_landmarks','word_landmarks_speechmark','word_landmarks_montreal','word_montrealforcedalignment','word_fave'};
        for i = 1:numel(fields)
            if isfield(data, fields{i})
                data.(fields{i})(words2Remove) = [];
            end
        end
        
        problemWords = data.silence(data.word_start_time) | data.silence(data.word_end_time); % for efficiency
        problemWordStartTimes = data.word_start_time(problemWords);
        problemWordEndTimes = data.word_end_time(problemWords);
        if isfield(data, 'word_duration')
            problemWordDurations = data.word_duration(problemWords);
        end
        
        %% move start times back from silent sections
%         silenceIdx = find(data.silence);
%         if isfield(data, 'word_duration') % must be first
%             for i = 1:numel(silenceIdx)
%                 selected = (problemWordStartTimes==silenceIdx(i));
%                 problemWordDurations(selected) = problemWordDurations(selected) - 1;
%             end
%         end
%         for i = 1:numel(silenceIdx)
%             selected = (problemWordStartTimes==silenceIdx(i));
%             problemWordStartTimes(selected) = problemWordStartTimes(selected) + 1;
%         end
        while any(data.silence(problemWordStartTimes))
            if isfield(data, 'word_duration') % must be first
                problemWordDurations(data.silence(problemWordStartTimes)) = problemWordDurations(data.silence(problemWordStartTimes)) - 1;
            end
            problemWordStartTimes(data.silence(problemWordStartTimes)) = problemWordStartTimes(data.silence(problemWordStartTimes)) + 1;
        end
        
        %% move end times up from silent sections
%         if isfield(data, 'word_duration') % must be first
%             for i = numel(silenceIdx):-1:1
%                 selected = (problemWordEndTimes==silenceIdx(i));
%                 problemWordDurations(selected) = problemWordDurations(selected) - 1;
%             end
%         end
%         for i = numel(silenceIdx):-1:1
%             selected = (problemWordEndTimes==silenceIdx(i));
%             problemWordEndTimes(selected) = problemWordEndTimes(selected) - 1;
%         end
        while any(data.silence(problemWordEndTimes))
            if isfield(data, 'word_duration') % must be first
                problemWordDurations(data.silence(problemWordEndTimes)) = problemWordDurations(data.silence(problemWordEndTimes)) - 1;
            end
            problemWordEndTimes(data.silence(problemWordEndTimes)) = problemWordEndTimes(data.silence(problemWordEndTimes)) - 1;
        end
        
        data.word_start_time(problemWords) = problemWordStartTimes;
        data.word_end_time(problemWords) = problemWordEndTimes;
        if isfield(data, 'word_duration')
            data.word_duration(problemWords) = problemWordDurations;
        end
        if isfield(data, 'word_landmarks') || isfield(data, 'word_landmarks_speechmark') || isfield(data, 'word_landmarks_montreal')
            error('TODO: change timing info on word_landmarks');
        end
        if isfield(data, 'word_montrealforcedalignment') || isfield(data, 'word_fave')
            error('TODO: change timing info on word_montrealforcedalignment and word_fave');
        end
        
        %% safety checks
        assert(~any(data.silence(data.word_start_time)));
        assert(~any(data.silence(data.word_end_time)));
        
        %% shift times forward to keep time now that we've deleted the sections
        forwardShift = cumsum(data.silence);
%         origStartTimes = data.word_start_time;
%         uniqueOrigStartTimes = unique(origStartTimes);
%         for i = 1:numel(uniqueOrigStartTimes)
%             t = uniqueOrigStartTimes(i);
%             selected = (origStartTimes == t);
%             data.word_start_time(selected) = data.word_start_time(selected) - forwardShift(t);
%             data.word_end_time(selected) = data.word_end_time(selected) - forwardShift(t);
%         end
        % identical to above but 10,000 times faster (really)
        if isfield(data, 'word_duration') %must be first
            data.word_duration = data.word_duration - (forwardShift(data.word_end_time)-forwardShift(data.word_start_time));
        end
        if isfield(data, 'word_landmarks')
            error('TODO: change timing info on wordLandmarks');
        end
        if isfield(data, 'word_montrealforcedalignment') || isfield(data, 'word_fave')
            error('TODO: change timing info on word_montrealforcedalignment and word_fave');
        end
        data.word_start_time = data.word_start_time - forwardShift(data.word_start_time);
        data.word_end_time = data.word_end_time - forwardShift(data.word_end_time);
    end
    
    data = rmfield(data, 'silence');
    toc
end