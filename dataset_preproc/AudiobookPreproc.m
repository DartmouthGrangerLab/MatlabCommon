% Eli Bowen
% 11/16/16
function [] = AudiobookPreproc ()
    % ASSUMES mp3s have already been interpolated to 32000Hz single channel wavs using ffmpeg (see convertmp3towav.sh: ffmpeg -i "$i" -ar 32000 -ac 1 "$name.wav")
    % ASSUMES BuildTextVocabulary.m was run first

    % Folders of audio to process
    paths = {};
%     paths = [paths,'Moby_Dick-Anthony_Heald']; % this is the original one
%     paths = [paths,'Moby_Dick-Norman_Dietz']; % (originally 32000Hz)
%     paths = [paths,'Moby_Dick-Stewart_Wills']; % (originally 32000Hz)

    paths = [paths,'Harry_Potter_and_the_Sorcerers_Stone-English']; % (originally 44100Hz)
%     paths = [paths,'Harry_Potter_and_the_Sorcerers_Stone-Japanese']; % (originally 44100Hz) % renamed the files in this folder since matlab can't handle one of the japanese characters
    paths = [paths,'Harry_Potter_and_the_Chamber_of_Secrets-English']; % (originally 44100Hz)
%     paths = [paths,'Harry_Potter_and_the_Chamber_of_Secrets-Japanese']; % (originally 44100Hz)

%     paths = [paths,'White_Fang_Unabridged-Flo_Gibson']; % unknown Hz (originally 22kHz or 44kHz)
%     paths = [paths,'White_Fang_Unabridged-Peter_Husmann']; % unknown Hz (originally 22kHz or 44kHz)
%     paths = [paths,'Wuthering_Heights_Unabridged-Charlton_Griffin']; % unknown Hz (originally 22kHz or 44kHz)
%     paths = [paths,'Wuthering_Heights_Unabridged-Emma_Messenger']; % unknown Hz (originally 22kHz or 44kHz)

    paths = [paths,'Harry_Potter_and_the_Prisoner_of_Azkaban-English'];
    paths = [paths,'Harry_Potter_and_the_Goblet_of_Fire-English'];
    paths = [paths,'Harry_Potter_and_the_Order_of_the_Phoenix-English'];
    paths = [paths,'Harry_Potter_and_the_Half_Blood_Prince-English'];
    paths = [paths,'Harry_Potter_and_the_Deathly_Hallows-English'];

% % % % %     paths = [paths,'Harry_Potter_and_the_Sorcerers_Stone-Japanese_Morio_Kazama']; % (originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Chamber_of_Secrets-Japanese_Morio_Kazama']; % (originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Prisoner_of_Azkaban-Japanese_Morio_Kazama']; % (originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part1']; % (originally 44100Hz)
% % % % %     paths = [paths,'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part2']; % (originally 44100Hz)

    profile = ComputerProfile();
    dictPath = fullfile(profile.dataset_dir, 'cmudict-0.7b.txt'); % arpabet dictionary
    vocabFile = fullfile(profile.dataset_dir, 'audio', 'vocabulary.mat'); % built by BuildTextVocabulary

    ws = warning();
    warning('off', 'backtrace');

    for pathNum = 1:numel(paths)
        path = fullfile(profile.dataset_dir, 'audio', paths{pathNum});
        delete(fullfile(path, 'audiobook_preproc_diary.txt'));
        diary(fullfile(path, 'audiobook_preproc_diary.txt'));
        disp(['--- beginning ',path,' ---']);
        TimeStamp();
        t = tic();

        % below, order is important!

        data = struct(); % dataset
        data.descriptor = lower(paths{pathNum});

        data = AudiobookPreprocAudio(path, data);                 % adds data.audio, .duration
        assert(data.sample_rate == 32000); % for now, let's stick with this (the only sample rate we've tested through every frontend)

        data = AudiobookPreprocWords(path, data);                 % adds data.word, .word_start_time, .word_end_time, .word_duration

        data = AudiobookPreprocPhonemes(path, data);              % adds data.phoneme, .phoneme_start_time, .phoneme_end_time, .phoneme_duration
        
        data = AudiobookPreprocWordIDs(vocabFile, data);          % adds data.word_id (requires that you've already run the script BuildTextVocabulary)

        data = AudiobookPreprocMarkSilenceAndJunk(data);          % adds data.silence

        data = AudiobookPreprocWordAudio(data);                   % adds data.word_audio

        data = AudiobookPreprocPhoneticSpellings(dictPath, data); % adds data.word_phonetic

        % below commented out - currently using montreal forced aligner exclusively
%         % below, use both or neither
%         data = AudiobookPreprocSpeechmarkForcedAlignment(data);   % adds data.word_speechmarks
%         data = AudiobookPreprocLandmarksSpeechmark(data);         % adds data.word_landmarks_speechmark
% %         RenderSpeechLandmarksSpeechmark(path, sampleRate); % in MatlabClusterNetwork

        save(fullfile(path, 'audiobook_preproc_dataset.mat'), '-struct', 'data', '-v7.3');

        toc(t)
        disp('DONE');
        diary off;
    end

    return; % in between running above and below, MUST run ExtractWords4MontrealForcedAligner script, then the montreal forced aligner itself, then FAVE first

    for pathNum = 1:numel(paths)
        path = fullfile(profile.dataset_dir, 'audio', paths{pathNum});
        delete(fullfile(path, 'audiobook_preproc_diary_part2.txt'));
        diary(fullfile(path, 'audiobook_preproc_diary_part2.txt'));
        disp(['--- beginning ',path,' part 2 ---']);
        TimeStamp();
        t = tic();

        % below, order is important!

        data = load(fullfile(path, 'audiobook_preproc_dataset.mat'));

        data = AudiobookPreprocMontrealForcedAlignment(path, data); % adds data.word_montrealforcedalignment

        data = AudiobookPreprocLandmarksMontreal(data);             % adds data.word_landmark_montreal

        data = AudiobookPreprocFAVE(path, data);                    % adds data.word_fave

%         RenderSpeechLandmarksMontreal(path, sampleRate); % in MatlabClusterNetwork

        save(fullfile(path, 'audiobook_preproc_dataset.mat'), '-struct', 'data', '-v7.3'); % overwrite

        toc(t)
        disp('DONE');
        diary off;
    end

    warning(ws); % return to original state
end