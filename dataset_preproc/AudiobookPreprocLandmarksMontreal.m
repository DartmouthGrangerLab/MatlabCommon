% Eli Boewn
% 5/26/2018
% INPUTS:
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocLandmarksMontreal (data)
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocLandmarksMontreal...');
    t = tic();

    if isfield(data, 'word_audio') && isfield(data, 'word_phonetic') && isfield(data, 'word_montrealforcedalignment')
        data.word_landmark_montreal = cell(numel(data.word_audio), 1);
%         parfor i = 1:numel(data.word_audio)
        for i = 1:numel(data.word_audio)
            if ~isempty(data.word_montrealforcedalignment{i}) && numel(strsplit(data.word_phonetic{i}, ' ')) >= 3
                data.word_landmark_montreal{i} = LandmarkDetectorMontreal(data.word_audio{i}, data.word_phonetic{i}, data.word_montrealforcedalignment{i});
            end
        end
    end
    toc(t)
end