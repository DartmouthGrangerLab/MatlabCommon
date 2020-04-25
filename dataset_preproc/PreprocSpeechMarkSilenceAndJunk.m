%Eli Bowen
%5/25/18
function [] = PreprocSpeechMarkSilenceAndJunk (path)
    disp('PreprocSpeechMarkSilenceAndJunk...');
    tic;
    load(fullfile(path, 'audio.mat'), 'audio', 'duration');
    
    %% mark silence
    silence = false(duration, 1);
    [stepSize,~] = StepSizeFromDatasetVersion(3);
    specIsSilent = CalculateSpectrogram4Frontend(FeatureTransformAudio(audio, 32000, 3), 'power', 3);
    specIsSilent = (sum(specIsSilent, 2) == 0); %like 10% for english, 35% for japanese
    for i = 1:size(specIsSilent, 1)-1
        if specIsSilent(i)
            silence(((i-1)*stepSize)+1:i*stepSize) = true;
        end
    end
    if specIsSilent(end)
        silence(((size(specIsSilent, 1)-1)*stepSize)+1:end) = true; %special handling because duration may not be a multiple of stepSize
    end
    
%     figure;
%     spectrogram = CalculateSpectrogram4Frontend(FeatureTransformAudio(audio, 32000, 3), 'power', 3);
%     subplot(2,1,1);imagesc(flipud(spectrogram(1:1000,:)'));
%     subplot(2,1,2);imagesc(double(specIsSilent(1:1000)'));
    
    %% manually mark junk
    if contains(path, 'Moby_Dick-Anthony_Heald')
        silence(1:33*32000) = true; %first 33 seconds of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif contains(path, 'Moby_Dick-Norman_Dietz')
        %choosing to remove nothing
    elseif contains(path, 'Moby_Dick-Stewart_Wills')
        silence(1:33*32000) = true; %first 33 seconds of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif contains(path, 'White_Fang_Unabridged-Flo_Gibson')
        silence(1:2*32000) = true; %first 2 seconds of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif contains(path, 'White_Fang_Unabridged-Peter_Husmann')
        silence(1:2*32000) = true; %first 2 seconds of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif contains(path, 'Wuthering_Heights_Unabridged-Emma_Messenger')
        silence(1:2*32000) = true; %first 2 seconds of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif contains(path, 'Wuthering_Heights_Unabridged-Charlton_Griffin')
        silence(1:2*32000) = true; %first 2 seconds of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif contains(path, 'Harry_Potter_and_the_Sorcerers_Stone-English')
        silence(1:33*32000) = true; %first 33 seconds of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif contains(path, 'Harry_Potter_and_the_Chamber_of_Secrets-English')
        silence(1:21*32000) = true; %first 21 seconds of this particular narration contain music, so crop them (31.25Hz*21~=657)
    elseif contains(path, 'Harry_Potter_and_the_Prisoner_of_Azkaban-English')
        silence(1:19*32000) = true; %first 19 seconds of this particular narration contain music, so crop them (31.25Hz*19~=594)
    elseif contains(path, 'Harry_Potter_and_the_Goblet_of_Fire-English')
        silence(1:26*32000) = true; %first 26 seconds of this particular narration contain music, so crop them (31.25Hz*26~=813)
    elseif contains(path, 'Harry_Potter_and_the_Order_of_the_Phoenix-English')
        silence(1:27*32000) = true; %first 27 seconds of this particular narration contain music, so crop them (31.25Hz*27~=844)
    elseif contains(path, 'Harry_Potter_and_the_Half_Blood_Prince-English')
        silence(1:27*32000) = true; %first 27 seconds of this particular narration contain music, so crop them (31.25Hz*27~=844)
    elseif contains(path, 'Harry_Potter_and_the_Deathly_Hallows-English')
        silence(1:27*32000) = true; %first 27 seconds of this particular narration contain music, so crop them (31.25Hz*27~=844)
    elseif contains(path, 'Harry_Potter_and_the_Sorcerers_Stone-Japanese_Morio_Kazama')
        silence(1:34*32000) = true; %first 34 seconds of this particular narration contain music, so crop them (31.25Hz*34~=?)
    elseif contains(path, 'Harry_Potter_and_the_Chamber_of_Secrets-Japanese_Morio_Kazama')
        silence(1:34*32000) = true; %first 34 seconds of this particular narration contain music, so crop them (31.25Hz*34~=?)
    elseif contains(path, 'Harry_Potter_and the_Prisoner_of_Azkaban-Japanese_Morio_Kazama')
        silence(1:34*32000) = true; %first 34 seconds of this particular narration contain music, so crop them (31.25Hz*34~=)
    elseif contains(path, 'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part1')
        silence(1:34*32000) = true; %first 34 seconds of this particular narration contain music, so crop them (31.25Hz*34~=)
    elseif contains(path, 'Harry_Potter_and_the_Goblet_of_Fire-Japanese_Morio_Kazama_Part2')
        silence(1:34*32000) = true; %first 34 seconds of this particular narration contain music, so crop them (31.25Hz*34~=)
    elseif contains(path, 'Harry_Potter_and_the_Sorcerers_Stone-Japanese')
        silence(1:33*32000) = true; %first 33 seconds of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif contains(path, 'Harry_Potter_and_the_Chamber_of_Secrets-Japanese')
        silence(1:33*32000) = true; %first 33 seconds of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    end
    
    save(fullfile(path, 'silence.mat'), 'silence', '-v7.3');
    toc
end