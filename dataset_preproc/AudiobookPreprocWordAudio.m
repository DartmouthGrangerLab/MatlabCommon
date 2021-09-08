% Eli Bowen
% 5/25/2018
% INPUTS:
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocWordAudio (data)
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocWordAudio...');
    t = tic();
    
    if isfield(data, 'audio') && isfield(data, 'word_start_time') && isfield(data, 'word_end_time')
        data.word_audio = cell(numel(data.word_start_time), 1);
        for wordNum = 1:numel(data.word_start_time)
            data.word_audio{wordNum} = data.audio(data.word_start_time(wordNum):data.word_end_time(wordNum));
        end
    end
    toc(t)
end