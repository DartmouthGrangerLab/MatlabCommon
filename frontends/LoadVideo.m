%Eli Bowen
%8/3/2020
%simple function for loading a video all at once in bulk
%INPUTS:
%   path
%   fileName
function [video,frameRate] = LoadVideo (path, fileName)
    validateattributes(path, {'char'}, {'nonempty','vector'});
    validateattributes(fileName, {'char'}, {'nonempty','vector'});
    
    vidH = VideoReader(fullfile(path, fileName));
    frameRate = vidH.FrameRate;
    
    nChan = 1;
    if vidH.BitsPerPixel > 8
        nChan = 3;
    end
    
    video = zeros(vidH.Height, vidH.Width, nChan, vidH.Duration * frameRate, 'uint8');
    count = 1;
    while hasFrame(vidH) && count <= vidH.Duration * frameRate
        video(:,:,:,count) = vidH.readFrame();
        count = count + 1;
    end
end