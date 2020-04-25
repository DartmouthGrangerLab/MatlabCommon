%Eli Bowen
%5/25/2018
function [] = PreprocSpeechWordAudio (path)
    disp('PreprocSpeechWordAudio...');
    t = tic();
    
    if logical(exist(fullfile(path, 'words.mat'), 'file'))
        load(fullfile(path, 'audio.mat'), 'audio');
        load(fullfile(path, 'words.mat'), 'wordStartTimes', 'wordEndTimes');
        
        wordAudio = cell(numel(wordStartTimes), 1);
        for wordNum = 1:numel(wordStartTimes)
            wordAudio{wordNum} = audio(wordStartTimes(wordNum):wordEndTimes(wordNum));
        end
        
        save(fullfile(path, 'wordaudio.mat'), 'wordAudio', '-v7.3', '-nocompression');
    end
    toc(t)
end