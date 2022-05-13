% Eli Bowen 8/3/2020
% simple function for loading a video all at once in bulk
% supports:
%   any file type supported by matlab's VideoReader (hopefully mjpeg in an avi or motion jpeg 2000 in an mj2, or VideoReader compatability will be iffy)
%   .mat files (must contain a variable called video (uint8 nRows x nCols x n_channels x n_frames) and one called frameRate (scalar numeric)
% INPUTS
%   path     - (char)
%   fileName - (char)
%   sz       - OPTIONAL [n_rows,n_cols] aka [height,width] - size of video; if provided, and video is a different size, we'll resize it automagically
% RETURNS
%   video     - n_rows x n_cols x n_chan x n_frames (uint8)
%   frameRate - scalar (int-valued numeric) in hz
% see also LoadVideoMetadata
function [video,frameRate] = LoadVideo(path, fileName, sz)
    validateattributes(path, {'char'}, {'nonempty','vector'}, 1);
    validateattributes(fileName, {'char'}, {'nonempty','vector'}, 2);
    if exist('sz', 'var') && ~isempty(sz)
        validateattributes(sz, {'numeric'}, {'nonempty','vector','positive','integer'});
    end

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

    if ~exist('sz', 'var') || isempty(sz)
        sz = [vidH.Height,vidH.Width];
    end
    resize = (sz(1) ~= vidH.Height || sz(2) ~= vidH.Width);

    n_frames = vidH.Duration * frameRate;
%     n_frames = vidH.NumFrames; % "not always available"
    video = zeros(sz(1), sz(2), n_chan, n_frames, 'uint8');
    count = 1;
    while hasFrame(vidH) && count <= n_frames
        if resize
            video(:,:,:,count) = imresize(vidH.readFrame(), sz);
        else
            video(:,:,:,count) = vidH.readFrame();
        end
        count = count + 1;
    end
%     video(:,:,:,count:end) = []; % should maybe do this, maybe not
end