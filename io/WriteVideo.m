% Eli Bowen 1/7/2021
% writes a video to file (just a wrapper around matlab code to save us time)
% INPUTS:
%   filePath - full path to file (including file name) - recommend .mj2 for lossless
%   video - nCols x nRows x nChannels x nFrames uint8 (range 0-->255) or double (range 0-->1)
%   frameRate
%   is_lossless - scalar logical (should video be lossless or lossy)
function [] = WriteVideo(filePath, video, frameRate, is_lossless)
    validateattributes(filePath, {'char'}, {'nonempty','vector'}, 1);
    validateattributes(video, {'uint8','double'}, {'nonempty','ndims',4}, 2);
    validateattributes(frameRate, {'numeric'}, {'nonempty','scalar','positive'}, 3);
    validateattributes(is_lossless, {'logical'}, {'nonempty','scalar'}, 4);
    if isa(video, 'double')
        assert(max(video(:)) <= 1 && min(video(:)) >= 0); % range of double inputs must be 0-->1 (a matlab image convention)
        video = uint8(video .* 255);
    end
    
    % pad for video player compatability
    aspectRatio = size(video, 2) / size(video, 1);
    if ~is_lossless
        rows2Add = 0;
        cols2Add = 0;
        if aspectRatio > 16 / 9
            aspectRatio = 16 / 9; % pad vertically (rows) to reach 16:9
            rows2Add = round(size(video, 2) / aspectRatio - size(video, 1)); % yes divide
        else
            if aspectRatio < 4 / 3
                aspectRatio = 4 / 3; % pad horizontally (cols) to reach 4:3
                cols2Add = round(size(video, 1) * aspectRatio - size(video, 2));
            elseif aspectRatio > 4 / 3 && aspectRatio < 16 / 10 % between 4:3 and 16:10
                aspectRatio = 16 / 10; % pad horizontally (cols) to reach 16:10
                cols2Add = round(size(video, 1) * aspectRatio - size(video, 2));
            elseif aspectRatio > 16 / 10 && aspectRatio < 16 / 9 % between 16:10 and 16:9
                aspectRatio = 16 / 9; % pad horizontally (cols) to reach 16:9
                cols2Add = round(size(video, 1) * aspectRatio - size(video, 2));
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
    [path,fileNameNoExt,requestedExt] = fileparts(filePath);
    
    isUseFFMPEG = false;
    if strcmpi(requestedExt, '.mp4') || strcmpi(requestedExt, '.m4v')
        if is_lossless
            warning('WriteVideo() will try to make .mp4/.m4v lossless, but we recommend .mj2 file extensions for true lossless video');
        end
        if ispc() || ismac() % definitely can write mpeg-4, so let's use that
            v = VideoWriter(filePath, 'MPEG-4');
            if is_lossless
                v.Quality = 100; % range [0,100], 100 is best
            else
                v.Quality = 75; % range [0,100], 100 is best
            end
        else
            error('shitty centos doesnt support mpeg - even ffmpeg is a decade out of date - try .mj2');
%             isUseFFMPEG = true;
%             ffmpegTempFile = fullfile(path, [fileNameNoExt,'.mj2']);
%             v = VideoWriter(filePath, 'Archival'); % write as mj2, then convert via ffmpeg
        end
    elseif strcmpi(requestedExt, '.mj2')
        if is_lossless
            % we no longer save lossless as mat files, because turns out matlab loads .mj2 files 2x-10x faster than compressed mat files (and they're the same size at high quality mj2s)
            % using below (lossless mjpeg2000) because video files are tiny and lossy artifacts pop out in retina code
            v = VideoWriter(filePath, 'Archival');
        else
            v = VideoWriter(filePath, 'Motion JPEG 2000');
            v.CompressionRatio = 5; % only for motion jpeg 2000, default = 10
        end
    elseif strcmpi(requestedExt, '.avi')
        if is_lossless
            error('.avi not supported with lossless - use .mj2');
        else
           % matlab only writes .avi files with mj2 compression - consider .mp4, which has superior compression
            v = VideoWriter(filePath, 'Motion JPEG AVI');
            v.CompressionRatio = 5; % only for motion jpeg 2000, default = 10
        end
    else
        error('unsupported file extension - try mp4 or mj2');
    end

    v.FrameRate = frameRate; % fps

    open(v);
    for frame = 1:size(video, 4)
        writeVideo(v, video(:,:,:,frame));
    end
    close(v);
    
    % nice try below, but centos cant even get ffmpeg working right
%     if isUseFFMPEG
%         [~,cmdout] = system('command -v ffmpeg'); % unlikely to succeed on windows
%         if contains(cmdout, 'ffmpeg', 'IgnoreCase', true)
%             if aspectRatio == 4 / 3
%                 aspectStr = '-aspect 4:3';
%             elseif aspectRatio == 16 / 10
%                 aspectStr = '-aspect 16:10';
%             elseif aspectRatio == 16 / 9
%                 aspectStr = '-aspect 16:9';
%             else
%                 aspectStr = ''; % you're on your own kid
%             end
%             if strcmpi(requestedExt, '.mp4') || strcmpi(requestedExt, '.m4v')
%                 % crf 0 is lossless, 23 is default, 51 is worst (for both libx264 and libx265)
%                 crf = '5';
%                 if is_lossless
%                     crf = '0';
%                 end
%                 status = system(['ffmpeg -i "',ffmpegTempFile,'" -c:v libx264 ',aspectStr,' -crf ',crf,' -pix_fmt yuv420p "',filePath,'"']);
% %                 status = system(['ffmpeg -i "',ffmpegTempFile,'" -c:v libx265 ',aspectStr,' -crf ',crf,' "',filePath,'"']); % matlab can't read these back in :(
%             else
%                 error('unexpected file extension for ffmpeg');
%             end
%             if status ~= 0
%                 if exist(filePath, 'file') > 0
%                     system(['rm ',filePath]); % something went wrong, remove duplicate if present
%                 end
%                 warning(['WriteVideo() failed to create ',filePath]);
%             end
%         else
%             error('needed ffmpeg, which we cant find');
%         end
%         system(['rm ',ffmpegTempFile]);
%     end
end