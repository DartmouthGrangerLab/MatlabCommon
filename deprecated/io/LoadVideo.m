% deprecated
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