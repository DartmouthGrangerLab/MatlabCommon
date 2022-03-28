% Eli Bowen 4/29/2021
% simple function for loading a video's metadata
% much faster than loading the video itself
% supports:
%   any file type supported by matlab's VideoReader (hopefully mjpeg in an avi or motion jpeg 2000 in an mj2, or VideoReader compatability will be iffy)
%   .mat files (must contain a variable called video (uint8 n_rows x n_cols x n_channels x n_frames) and one called frameRate (scalar numeric)
% INPUTS:
%   path
%   fileName
function [vidSize,frameRate] = LoadVideoMetadata(path, fileName)
    validateattributes(path, {'char'}, {'nonempty','vector'}, 1);
    validateattributes(fileName, {'char'}, {'nonempty','vector'}, 2);

    if endsWith(fileName, '.mat')
        load(fullfile(path, fileName), 'video', 'frameRate');
        validateattributes(video, {'uint8'}, {'nonempty'});
        validateattributes(frameRate, {'numeric'}, {'nonempty','scalar','positive','integer'});
        return
    end

    vidH = VideoReader(fullfile(path, fileName));
    frameRate = vidH.FrameRate;
    
    n_chan = 1;
    if vidH.BitsPerPixel > 8
        n_chan = 3;
    end

    n_frames = vidH.Duration * frameRate;
%     n_frames = vidH.NumFrames; % "not always available"
    vidSize = [vidH.Height,vidH.Width,n_chan,n_frames];
end