%Eli Boewn
%5/26/2018
function [] = PreprocSpeechLandmarksMontreal (path)
    disp('PreprocSpeechLandmarksMontreal...');
    tic;
    if logical(exist(fullfile(path, 'wordaudio.mat'), 'file')) && logical(exist(fullfile(path, 'wordsphonetic.mat'), 'file')) && logical(exist(fullfile(path, 'wordsmontrealforcedalignment.mat'), 'file'))
        load(fullfile(path, 'wordaudio.mat'), 'wordAudio');
        load(fullfile(path, 'wordsphonetic.mat'), 'wordsPhonetic');
        load(fullfile(path, 'wordsmontrealforcedalignment.mat'), 'wordsMontrealForcedAlignment');
        
        wordLandmarksMontreal = cell(numel(wordAudio), 1);
%         parfor i = 1:numel(wordAudio)
        for i = 1:numel(wordAudio)
            if ~isempty(wordsMontrealForcedAlignment{i}) && numel(strsplit(wordsPhonetic{i}, ' ')) >= 3
                wordLandmarksMontreal{i} = LandmarkDetectorMontreal(wordAudio{i}, wordsPhonetic{i}, wordsMontrealForcedAlignment{i});
            end
        end
        
        save(fullfile(path, 'wordlandmarksmontreal.mat'), 'wordLandmarksMontreal', '-v7.3', '-nocompression');
    end
    toc
end
