%Eli Boewn
%5/26/2018
function [] = PreprocSpeechLandmarksSpeechmark (path)
    disp('PreprocSpeechLandmarksSpeechmark...');
    t = tic();
    if logical(exist(fullfile(path, 'wordaudio.mat'), 'file')) && logical(exist(fullfile(path, 'wordsphonetic.mat'), 'file')) && logical(exist(fullfile(path, 'wordspeechmarks.mat'), 'file'))
        load(fullfile(path, 'wordaudio.mat'), 'wordAudio');
        load(fullfile(path, 'wordsphonetic.mat'), 'wordsPhonetic');
        load(fullfile(path, 'wordspeechmarks.mat'), 'wordSpeechmarks');

        wordLandmarksSpeechmark = cell(numel(wordAudio), 1);
%         parfor i = 1:numel(wordAudio)
        for i = 1:numel(wordAudio)
            if (wordSpeechmarks.startPhon2(i) ~= 0 || wordSpeechmarks.startPhon3(i) ~= 0) && numel(strsplit(wordsPhonetic{i}, ' ')) >= 3
                wordLandmarksSpeechmark{i} = LandmarkDetectorSpeechmark(wordAudio{i}, wordsPhonetic{i}, wordSpeechmarks.startPhon2(i), wordSpeechmarks.startPhon3(i), wordSpeechmarks.stopPhon3(i));
            end
        end

        save(fullfile(path, 'wordlandmarksspeechmark.mat'), 'wordLandmarksSpeechmark', '-v7.3', '-nocompression');
    end
    toc(t)
end
