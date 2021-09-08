% Eli Bowen
% 5/25/2018
% INPUTS:
%   path - (char) - data folder
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocAudio (path, data)
    validateattributes(path, {'char'}, {'nonempty'});
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocAudio...');
    t = tic();
    
    [~,filePath] = CountFileType(path, 'wav', false);
    data.audio = [];
    for i = 1:numel(filePath)
        disp(filePath{i});

        [y,fs] = audioread(filePath{i});
        if ~isfield(data, 'sample_rate')
            data.sample_rate = fs;
        else
            assert(fs == data.sample_rate); % must all be identical!
        end

        data.audio = [data.audio;y];
    end

    data.duration = numel(data.audio);

    toc(t)
end