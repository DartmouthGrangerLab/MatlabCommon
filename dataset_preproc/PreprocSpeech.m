%Eli Bowen
%11/16/16
function [] = PreprocSpeech ()
    %ASSUMES mp3s have already been interpolated to 32000Hz single channel wavs using ffmpeg (see convertmp3towav.sh: ffmpeg -i "$i" -ar 32000 -ac 1 "$name.wav")
    %ASSUMES BuildTextVocabulary.m was run first
    
    %% Folders of audio to process
    fileLocation = fullfile('/pdata', 'ebowen', 'datasets', 'audio');
    paths = {};
%     paths = [paths,'Moby_Dick-Anthony_Heald']; %this is the original one
%     paths = [paths,'Moby_Dick-Norman_Dietz']; %(originally 32000Hz)
%     paths = [paths,'Moby_Dick-Stewart_Wills']; %(originally 32000Hz)
%     paths = [paths,'Harry_Potter_and_the_Sorcerers_Stone-English']; %(originally 44100Hz)
%     paths = [paths,'Harry_Potter_and_the_Sorcerers_Stone-Japanese']; %(originally 44100Hz) %renamed the files in this folder since matlab can't handle one of the japanese characters
    paths = [paths,'Harry_Potter_and_the_Chamber_of_Secrets-English']; %(originally 44100Hz)
%     paths = [paths,'Harry_Potter_and_the_Chamber_of_Secrets-Japanese']; %(originally 44100Hz)

%     paths = [paths,'White_Fang_Unabridged-Flo_Gibson']; %unknown Hz (originally 22kHz or 44kHz)
%     paths = [paths,'White_Fang_Unabridged-Peter_Husmann']; %unknown Hz (originally 22kHz or 44kHz)
%     paths = [paths,'Wuthering_Heights_Unabridged-Charlton_Griffin']; %unknown Hz (originally 22kHz or 44kHz)
%     paths = [paths,'Wuthering_Heights_Unabridged-Emma_Messenger']; %unknown Hz (originally 22kHz or 44kHz)

    paths = [paths,'Harry_Potter_and_the_Prisoner_of_Azkaban-English'];
    paths = [paths,'Harry_Potter_and_the_Goblet_of_Fire-English'];
    paths = [paths,'Harry_Potter_and_the_Order_of_the_Phoenix-English'];
    paths = [paths,'Harry_Potter_and_the_Half_Blood_Prince-English'];
    paths = [paths,'Harry_Potter_and_the_Deathly_Hallows-English'];

% % % % %     paths = [paths,'Harry_Potter_and_the_Sorcerers_Stone-Japanese_Morio_Kazama']; %(originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Chamber_of_Secrets-Japanese_Morio_Kazama']; %(originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Prisoner_of_Azkaban-Japanese_Morio_Kazama']; %(originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part1']; %(originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part2']; %(originally 44100Hz)

    %% Begin
    for pathNum = 1:numel(paths)
        path = fullfile(fileLocation, paths{pathNum});
        disp(['--- beginning ',path,' ---']);
        tic();
        
        %below, order is important!
        
%         PreprocSpeechAudio(path);
        
%         PreprocSpeechWords(path);
        
%         PreprocSpeechMarkSilenceAndJunk(path);
        
%         PreprocSpeechWordAudio(path);

%         PreprocSpeechPhonemes(path);
        
%         dictPath = fullfile('/pdata', 'ebowen', 'project_videogame', 'cmudict-0.7b.txt'); %arpabet dictionary
%         PreprocSpeechPhoneticSpellings(path, dictPath);
        
%         PreprocSpeechSpeechmarkForcedAlignment(path);
        PreprocSpeechLandmarksSpeechmark(path);
%         RenderSpeechLandmarksSpeechmark(path); %in MatlabClusterNetwork
        
%         PreprocSpeechMontrealForcedAlignment(path); %must run ExtractWords4MontrealForcedAligner script, then the montreal forced aligner itself first
%         PreprocSpeechFAVE(path); %must run ExtractWords4MontrealForcedAligner script, then the montreal forced aligner itself, then FAVE first
        PreprocSpeechLandmarksMontreal(path);
%         RenderSpeechLandmarksMontreal(path); %in MatlabClusterNetwork

%         vocabFile = fullfile(fileLocation, 'vocabulary.mat');
%         PreprocSpeechWordIDs(path, vocabFile);
        
        toc
    end
    disp('DONE');
end