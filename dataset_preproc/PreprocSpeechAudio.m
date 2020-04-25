% Eli Bowen
% 5/25/2018
function [] = PreprocSpeechAudio (path)
    disp('PreprocSpeechAudio...');
    t = tic();
    listing = dir(fullfile(path, '*.wav'));
    audio = [];
    for i = 1:numel(listing)
        disp(listing(i).name);
        [y,Fs] = audioread(fullfile(path, listing(i).name));
        assert(Fs==32000);
        audio = [audio;y];
    end
    
    duration = numel(audio);
    
    %% save
    save(fullfile(path, 'audio.mat'), 'audio', 'duration', '-v7.3', '-nocompression');
    toc(t)
end

