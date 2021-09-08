% Eli Boewn
% 5/26/2018
% INPUTS:
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocLandmarksSpeechmark (data)
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocLandmarksSpeechmark...');
    t = tic();

    if isfield(data, 'word_audio') && isfield(data, 'word_phonetic') && isfield(data, 'word_speechmarks')
        data.word_landmarks_speechmark = cell(numel(data.word_audio), 1);
%         parfor i = 1:numel(data.word_audio)
        for i = 1:numel(data.word_audio)
            if (data.word_speechmarks.startPhon2(i) ~= 0 || data.word_speechmarks.startPhon3(i) ~= 0) && numel(strsplit(data.word_phonetic{i}, ' ')) >= 3
                data.word_landmarks_speechmark{i} = LandmarkDetectorSpeechmark(data.word_audio{i}, data.word_phonetic{i}, data.word_speechmarks.startPhon2(i), data.word_speechmarks.startPhon3(i), data.word_speechmarks.stopPhon3(i));
            end
        end
    end

    toc(t)
end