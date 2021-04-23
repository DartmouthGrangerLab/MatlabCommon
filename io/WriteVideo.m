%Eli Bowen
%1/7/2021
% writes a video to file (just a wrapper around matlab code to save us time)
%INPUTS:
%   filePath - full path to file (including file name) (extension will be corrected if wrong)
%   video - nCols x nRows x nChannels x nFrames uint8 (range 0-->255) or double (range 0-->1)
%   frameRate
%   isLossless - scalar logical (should video be lossless or lossy)
function [] = WriteVideo (filePath, video, frameRate, isLossless)
    validateattributes(filePath, {'char'}, {'nonempty','vector'});
    validateattributes(video, {'uint8','double'}, {'nonempty','ndims',4});
    validateattributes(frameRate, {'numeric'}, {'nonempty','scalar','positive'});
    validateattributes(isLossless, {'logical'}, {'nonempty','scalar'});
    if isa(video, 'double')
        assert(max(video(:)) <= 1 && min(video(:)) >= 0); % range of double inputs must be 0-->1 (a matlab image convention)
        video = uint8(video .* 255);
    end

    [path,fileName,~] = fileparts(filePath); % strip extension
    if isLossless
        % using below (lossless mjpeg2000) because video files are tiny and artifacts pop out in retina code
        v = VideoWriter(fullfile(path, [fileName,'.mj2']), 'Archival');
        % we no longer save lossless as mat files, because turns out matlab loads .mj2 files 2x-10x faster than compressed mat files (and they're the same size at high quality mj2s)
    else
        % below, mjpeg200, has smaller files for similar quality vs mjpeg avi (and takes less time to write due to it supporting grayscale)
        v = VideoWriter(fullfile(path, [fileName,'.mj2']), 'Motion JPEG 2000');
        v.CompressionRatio = 5; % only for motion jpeg 2000, default = 10
    end

    v.FrameRate = frameRate; % fps

    open(v);
    for frame = 1:size(video, 4)
        writeVideo(v, video(:,:,:,frame));
    end
    close(v);
end