% Eli Bowen
% 4/29/2021
% simple function for loading a video's metadata
% much faster than loading the video itself
%supports:
%   any file type supported by matlab's VideoReader (hopefully mjpeg in an avi or motion jpeg 2000 in an mj2, or VideoReader compatability will be iffy)
%   .mat files (must contain a variable called video (uint8 nRows x nCols x nChannels x nFrames) and one called frameRate (scalar numeric)
%INPUTS:
%   path
%   fileName
function [vidSize,frameRate] = LoadVideoMetadata (path, fileName)
    validateattributes(path, {'char'}, {'nonempty','vector'});
    validateattributes(fileName, {'char'}, {'nonempty','vector'});
    
    if endsWith(fileName, '.mat')
        load(fullfile(path, fileName), 'video', 'frameRate');
        validateattributes(video, {'uint8'}, {'nonempty'});
        validateattributes(frameRate, {'numeric'}, {'nonempty','scalar','positive','integer'});
        return;
    end
    
    vidH = VideoReader(fullfile(path, fileName));
    frameRate = vidH.FrameRate;
    
    nChan = 1;
    if vidH.BitsPerPixel > 8
        nChan = 3;
    end
    
    nFrames = vidH.Duration * frameRate;
%     nFrames = vidH.NumFrames; % "not always available"
    vidSize = [vidH.Height,vidH.Width,nChan,nFrames];
end