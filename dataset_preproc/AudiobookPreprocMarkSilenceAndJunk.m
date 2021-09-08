% Eli Bowen
% 5/25/18
% INPUTS:
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocMarkSilenceAndJunk (data)
    validateattributes(data, {'struct'}, {'nonempty','scalar'});
    
    disp('AudiobookPreprocMarkSilenceAndJunk...');
    t = tic();

    %% mark silence
    data.silence = false(data.duration, 1);
    stepSize = 1024;
    specIsSilent = AudioCalculateSpectrogramFromFeats(AudioFeatTransform(data.audio, data.sample_rate, 'stft', stepSize), 'power', 'stft');
    specIsSilent = (sum(specIsSilent, 2) == 0); % like 10% for english, 35% for japanese
    for i = 1:size(specIsSilent, 1)-1
        if specIsSilent(i)
            data.silence(((i-1)*stepSize)+1:i*stepSize) = true;
        end
    end
    if specIsSilent(end)
        data.silence(((size(specIsSilent, 1)-1)*stepSize)+1:end) = true; % special handling because duration may not be a multiple of stepSize
    end
    
%     figure;
%     spectrogram = CalculateSpectrogram4Frontend(FeatureTransformAudio(data.audio, sampleRate, 3), 'power', 3);
%     subplot(2,1,1);imagesc(flipud(spectrogram(1:1000,:)'));
%     subplot(2,1,2);imagesc(double(specIsSilent(1:1000)'));
    
    %% manually mark junk
    if strcmp(data.descriptor, 'moby_dick-anthony_heald')
        junkDuration = 33; % first 33 sec of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif strcmp(data.descriptor, 'moby_dick-norman_dietz')
        junkDuration = 0; % choosing to remove nothing
    elseif strcmp(data.descriptor, 'moby_dick-stewart_wills')
        junkDuration = 33; % first 33 sec of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif strcmp(data.descriptor, 'white_fang_unabridged-flo_gibson')
        junkDuration = 2; % first 2 sec of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif strcmp(data.descriptor, 'white_fang_unabridged-peter_husmann')
        junkDuration = 2; % first 2 sec of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif strcmp(data.descriptor, 'wuthering_heights_unabridged-emma_messenger')
        junkDuration = 2; % first 2 sec of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif strcmp(data.descriptor, 'wuthering_heights_unabridged-charlton_griffin')
        junkDuration = 2; % first 2 sec of this particular narration contain someone else's voice, so crop them (31.25Hz*2~=62)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_sorcerers_stone-english')
        junkDuration = 33; % first 33 sec of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_chamber_of_secrets-english')
        junkDuration = 21; % first 21 sec of this particular narration contain music, so crop them (31.25Hz*21~=657)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_prisoner_of_azkaban-english')
        junkDuration = 19; % first 19 sec of this particular narration contain music, so crop them (31.25Hz*19~=594)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_goblet_of_fire-english')
        junkDuration = 26; % first 26 sec of this particular narration contain music, so crop them (31.25Hz*26~=813)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_order_of_the_phoenix-english')
        junkDuration = 27; % first 27 sec of this particular narration contain music, so crop them (31.25Hz*27~=844)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_half_blood_prince-english')
        junkDuration = 27; % first 27 sec of this particular narration contain music, so crop them (31.25Hz*27~=844)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_deathly_hallows-english')
        junkDuration = 27; % first 27 sec of this particular narration contain music, so crop them (31.25Hz*27~=844)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_sorcerers_stone-japanese_morio_kazama')
        junkDuration = 34; % first 34 sec of this particular narration contain music, so crop them (31.25Hz*34~=?)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_chamber_of_secrets-japanese_morio_kazama')
        junkDuration = 34; % first 34 sec of this particular narration contain music, so crop them (31.25Hz*34~=?)
    elseif strcmp(data.descriptor, 'harry_potter_and the_prisoner_of_azkaban-japanese_morio_kazama')
        junkDuration = 34; % first 34 sec of this particular narration contain music, so crop them (31.25Hz*34~=)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_goblet_of_fire-japanese_morio_kazama_part1')
        junkDuration = 34; % first 34 sec of this particular narration contain music, so crop them (31.25Hz*34~=)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_goblet_of_fire-japanese_morio_kazama_part2')
        junkDuration = 34; % first 34 sec of this particular narration contain music, so crop them (31.25Hz*34~=)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_sorcerers_stone-japanese')
        junkDuration = 33; % first 33 sec of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    elseif strcmp(data.descriptor, 'harry_potter_and_the_chamber_of_secrets-japanese')
        junkDuration = 33; % first 33 sec of this particular narration contain music, so crop them (31.25Hz*33~=1032)
    end

    data.silence(1:junkDuration*data.sample_rate) = true;

    toc(t)
end