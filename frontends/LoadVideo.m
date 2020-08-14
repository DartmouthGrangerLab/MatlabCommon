%Eli Bowen
%8/3/2020
%simple function for loading a video all at once in bulk
%supports:
%   any file type supported by matlab's VideoReader (hopefully mjpeg in an avi or motion jpeg 2000 in an mj2, or VideoReader compatability will be iffy)
%   .mat files (must contain a variable called video (uint8 nRows x nCols x nChannels x nFrames) and one called frameRate (scalar numeric)
%INPUTS:
%   path
%   fileName
%   size - OPTIONAL - [nRows,nCols] aka [height,width], if provided, and video is a different size, we'll resize it automagically
function [video,frameRate] = LoadVideo (path, fileName, size)
    validateattributes(path, {'char'}, {'nonempty','vector'});
    validateattributes(fileName, {'char'}, {'nonempty','vector'});
    if exist('size', 'var') && ~isempty(size)
        validateattributes(size, {'numeric'}, {'nonempty','vector','positive','integer'});
    end
    
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
    
    if ~exist('size', 'var') || isempty(size)
        size = [vidH.Height,vidH.Width];
    end
    resize = (size(1) ~= vidH.Height || size(2) ~= vidH.Width);
    
    video = zeros(size(1), size(2), nChan, vidH.Duration * frameRate, 'uint8');
    count = 1;
    while hasFrame(vidH) && count <= vidH.Duration * frameRate
        if resize
            video(:,:,:,count) = imresize(vidH.readFrame(), size);
        else
            video(:,:,:,count) = vidH.readFrame();
        end
        count = count + 1;
    end
end