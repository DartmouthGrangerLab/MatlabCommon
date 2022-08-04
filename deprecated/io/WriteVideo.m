% deprecated
function [] = WriteVideo(filePath, video, frameRate, is_lossless)
    io.WriteVideo(filePath, video, frameRate, is_lossless);
end