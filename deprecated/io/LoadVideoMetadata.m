% deprecated
function [vidSz,frameRate] = LoadVideoMetadata(path, fileName)
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
    vidSz = [vidH.Height,vidH.Width,n_chan,n_frames];
end