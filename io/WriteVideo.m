% Eli Bowen
% 1/7/2021
% writes a video to file (just a wrapper around matlab code to save us time)
% INPUTS:
%   filePath - full path to file (including file name) (extension will be corrected if wrong)
%   video - nCols x nRows x nChannels x nFrames uint8 (range 0-->255) or double (range 0-->1)
%   frameRate
%   isLossless - scalar logical (should video be lossless or lossy)
% RETURNS:
%   filePath - true written file path - extension may have been changed from input filePath
function [filePath] = WriteVideo (filePath, video, frameRate, isLossless)
    validateattributes(filePath, {'char'}, {'nonempty','vector'});
    validateattributes(video, {'uint8','double'}, {'nonempty','ndims',4});
    validateattributes(frameRate, {'numeric'}, {'nonempty','scalar','positive'});
    validateattributes(isLossless, {'logical'}, {'nonempty','scalar'});
    if isa(video, 'double')
        assert(max(video(:)) <= 1 && min(video(:)) >= 0); % range of double inputs must be 0-->1 (a matlab image convention)
        video = uint8(video .* 255);
    end
    
    % pad for video player compatability
    aspectRatio = size(video, 2) / size(video, 1);
    if ~isLossless
        rows2Add = 0;
        cols2Add = 0;
        if aspectRatio > 16 / 9
            aspectRatio = 16 / 9; % pad vertically (rows) to reach 16:9
            rows2Add = round(size(video, 2) / aspectRatio); % yes divide
        else
            if aspectRatio < 4 / 3
                aspectRatio = 4 / 3; % pad horizontally (cols) to reach 4:3
                cols2Add = round(size(video, 1) * aspectRatio);
            elseif aspectRatio > 4 / 3 && aspectRatio < 16 / 10 % between 4:3 and 16:10
                aspectRatio = 16 / 10; % pad horizontally (cols) to reach 16:10
                cols2Add = round(size(video, 1) * aspectRatio);
            elseif aspectRatio > 16 / 10 && aspectRatio < 16 / 9 % between 16:10 and 16:9
                aspectRatio = 16 / 9; % pad horizontally (cols) to reach 16:9
                cols2Add = round(size(video, 1) * aspectRatio);
            end
        end
        if rows2Add > 0
            padding1 = zeros(floor(rows2Add/2), size(video, 2), size(video, 3), size(video, 4), 'like', video);
            padding2 = zeros(ceil(rows2Add/2),  size(video, 2), size(video, 3), size(video, 4), 'like', video);
            video = [padding1;video;padding2];
        end
        if cols2Add > 0
            padding1 = zeros(size(video, 1), floor(cols2Add/2), size(video, 3), size(video, 4), 'like', video);
            padding2 = zeros(size(video, 1), ceil(cols2Add/2),  size(video, 3), size(video, 4), 'like', video);
            video = [padding1,video,padding2];
        end
    end
    
    % strip extension
    [path,fileName,requestedExt] = fileparts(filePath);
    filePath = fullfile(path, fileName);
    
    isUseFFMPEG = false;
    if isLossless
        filePath = [filePath,'.mj2'];
        % using below (lossless mjpeg2000) because video files are tiny and lossy artifacts pop out in retina code
        v = VideoWriter(filePath, 'Archival');
        v.MJ2BitDepth = 8;
        % we no longer save lossless as mat files, because turns out matlab loads .mj2 files 2x-10x faster than compressed mat files (and they're the same size at high quality mj2s)
    elseif strcmpi(requestedExt, 'mp4') && (ispc() || ismac())
        filePath = [filePath,'.mp4'];
        v = VideoWriter(filePath, 'MPEG-4');
        v.Quality = 75; % range [0,100], 100 is best
    else
        filePath = [filePath,'.mj2'];
        % mjpeg2000 has smaller files for similar quality vs mjpeg avi (and takes less time to write due to it supporting grayscale)
        v = VideoWriter([filePath,'.mj2'], 'Motion JPEG 2000');
        v.CompressionRatio = 5; % only for motion jpeg 2000, default = 10
        v.MJ2BitDepth = 8;
        
        if strcmpi(requestedExt, 'mp4') && isFFMPEG
            isUseFFMPEG = true;
        end
    end

    v.FrameRate = frameRate; % fps

    open(v);
    for frame = 1:size(video, 4)
        writeVideo(v, video(:,:,:,frame));
    end
    close(v);
    
    if isUseFFMPEG
        [~,cmdout] = system('command -v ffmpeg'); % unlikely to succeed on windows
        if contains(cmdout, 'ffmpeg', 'IgnoreCase', true)
            if aspectRatio == 4 / 3
                aspectStr = '-aspect 4:3';
            elseif aspectRatio == 16 / 10
                aspectStr = '-aspect 16:10';
            elseif aspectRatio == 16 / 9
                aspectStr = '-aspect 16:9';
            else
                aspectStr = '';
            end
            status = system(['ffmpeg -i "',filePath,'.mj2" -c:v libx265 ',aspectStr,' -crf 5 "',filePath,'.mp4"']);
            if status == 0
                system(['rm ',filePath,'.mj2']);
            else
                system(['rm ',filePath,'.mp4']); % something went wrong, remove duplicate if present
            end
        end
    end
end