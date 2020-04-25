%Eli Bowen
%12/22/2018
%INPUTS:
%   wordAudio - audio stream (1d array of PCM) from word start to word end
%   wordPhonetic - string of the phonetic spelling of the word
%   montrealForcedAlignment
%RETURNS:
%   landmarks - cell array of structs, one per gram (landmarks{2} are landmarks for gram 2)
function [landmarks] = LandmarkDetectorMontreal (wordAudio, wordPhonetic, montrealForcedAlignment)
    grams = strsplit(wordPhonetic, ' ');
    grams = regexprep(grams, '\d', '');
    
    plosives = {'P','T','K','D','G','B'}; %plosives PTK are voiceless, BDG are unaspirated
    fricatives = {'S','SH','Z','ZH','TH','DH','V','HH','F','CH','JH'}; %fricatives HH only kinda sorta counts. Couldn't quickly find documentation on CH or JH

    spec = AudioCalculateSpectrogramFromFeats(AudioFeatTransform(wordAudio, 32000, 'stft', 128), 'power', 'stft');
    
    sumPowerMostFreqs = sum(spec(:,3:end), 2);
    sumPowerMostFreqs = smooth(sumPowerMostFreqs, 5, 'moving');
    sumPowerDiffMostFreqs = sumPowerMostFreqs(2:end)-sumPowerMostFreqs(1:end-1);
    sumPowerDiffMostFreqs = sumPowerDiffMostFreqs ./ max(abs(sumPowerDiffMostFreqs));
    
    sumPowerLowerFreqs = sum(spec(:,5:end/4), 2);
    sumPowerLowerFreqs = smooth(sumPowerLowerFreqs, 3, 'moving');
    
    sumPowerUpperFreqs = sum(spec(:,end/2:end), 2);
    sumPowerUpperFreqs = smooth(sumPowerUpperFreqs, 3, 'moving');
    sumPowerDiffUpperFreqs = sumPowerUpperFreqs(2:end)-sumPowerUpperFreqs(1:end-1);
    sumPowerDiffUpperFreqs = sumPowerDiffUpperFreqs ./ max(abs(sumPowerDiffUpperFreqs));
    
    landmarks = cell(numel(grams), 1);
    for i = 1:numel(grams)
        landmarks{i} = struct();
        
        if i == 1
            landmarks{i}.startPhon = max(1, round(montrealForcedAlignment.startTime(i)/128) - 1);
            landmarks{i}.stopPhon = max(3, round(montrealForcedAlignment.endTime(i)/128) - 1);
        else
            landmarks{i}.startPhon = landmarks{i-1}.stopPhon + 1;
            landmarks{i}.stopPhon = max(landmarks{i-1}.stopPhon + 3, round(montrealForcedAlignment.endTime(i)/128) - 1);
        end
    end
    
    % fix overflow
    if landmarks{end}.stopPhon > size(spec, 1)
        landmarks{end}.stopPhon = size(spec, 1);
        for i = numel(grams):-1:2
            if landmarks{i}.startPhon <= landmarks{i}.stopPhon - 2
                break;
            end
            landmarks{i}.startPhon = landmarks{i}.stopPhon - 2;
            landmarks{i-1}.stopPhon = landmarks{i}.startPhon - 1;
        end
    end
    
    for i = 1:numel(grams)
        if ~isempty(StringFind(plosives, grams{i}, true))
            if i == 1
                [~,landmarks{i}.startPlosion] = max(sumPowerDiffMostFreqs(1:ceil(landmarks{i}.stopPhon)));
            else
                [~,landmarks{i}.startPlosion] = max(sumPowerDiffMostFreqs(landmarks{i-1}.stopPhon:min(end,ceil(landmarks{i}.stopPhon))));
                landmarks{i}.startPlosion = landmarks{i-1}.stopPhon + landmarks{i}.startPlosion;
            end
            try
                [peakVals,peakIdxs] = findpeaks(-sumPowerDiffMostFreqs(landmarks{i}.startPlosion+1:landmarks{i}.stopPhon));
            catch %often fails because we only passed it 2 timepoints
                peakVals = [];
                peakIdxs = [];
            end
            peakIdxs(peakVals < -0.2) = []; %want only peaks that are less than zero. remember peakVals is -sumPowerDiffMostFreqs, so remove peakVals<0 not >0
            if isempty(peakIdxs)
                landmarks{i}.stopPlosion = landmarks{i}.startPlosion + 2;
            else
                landmarks{i}.stopPlosion = landmarks{i}.startPlosion + peakIdxs(1); %first local minimum <0 after startPlosion
            end
        elseif ~isempty(StringFind(fricatives, grams{i}, true))
            if strcmp(grams{i}, 'V')
                %we can't really improve on their vowel boundaries in this case (without new code)
                if i == 1
                    landmarks{i}.startFriction = 1;
                else
                    landmarks{i}.startFriction = landmarks{i-1}.stopPhon + 1;
                end
                landmarks{i}.stopFriction = landmarks{i}.stopPhon;
            else
                if i == 1
                    [~,frictionPeak] = max(sumPowerUpperFreqs(1:landmarks{i}.stopPhon-1));
                    startFricA = find(sumPowerDiffUpperFreqs(1:frictionPeak-1) <= 0, 1, 'last');
                    startFricB = find(sumPowerUpperFreqs(1:frictionPeak-1) < max(sumPowerUpperFreqs)*0.5, 1, 'last');
                    if isempty(startFricA)
                        landmarks{i}.startFriction = frictionPeak - 1;
                    elseif ~isempty(startFricA) && isempty(startFricB)
                        landmarks{i}.startFriction = startFricA;
                    elseif ~isempty(startFricA) && ~isempty(startFricB)
                        landmarks{i}.startFriction = min(startFricA, startFricB);
                    end
                else
                    [~,frictionPeak] = max(sumPowerUpperFreqs(landmarks{i-1}.stopPhon+1:landmarks{i}.stopPhon-1));
                    frictionPeak = landmarks{i-1}.stopPhon + frictionPeak;
                    startFricA = find(sumPowerDiffUpperFreqs(landmarks{i-1}.stopPhon:frictionPeak-1) <= 0, 1, 'last');
                    startFricB = find(sumPowerUpperFreqs(landmarks{i-1}.stopPhon:frictionPeak-1) < max(sumPowerUpperFreqs)*0.5, 1, 'last');
                    if isempty(startFricA)
                        landmarks{i}.startFriction = frictionPeak - 1;
                    elseif ~isempty(startFricA) && isempty(startFricB)
                        landmarks{i}.startFriction = landmarks{i-1}.stopPhon + startFricA;
                    elseif ~isempty(startFricA) && ~isempty(startFricB)
                        landmarks{i}.startFriction = landmarks{i-1}.stopPhon + min(startFricA, startFricB);
                    end
                end
                landmarks{i}.stopFriction = find(sumPowerUpperFreqs(frictionPeak+1:landmarks{i}.stopPhon-1) < sumPowerLowerFreqs(frictionPeak+1:landmarks{i}.stopPhon-1), 1); %where the blue and pink lines cross
                if isempty(landmarks{i}.stopFriction) || landmarks{i}.stopFriction == 1
                    landmarks{i}.stopFriction = max([landmarks{i}.stopPhon,frictionPeak+1,landmarks{i}.startFriction+2]);
                else
                    landmarks{i}.stopFriction = landmarks{i}.stopFriction + frictionPeak;
                end
            end
        end
        
        %clean-up
        landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, i);
        
        %add extra fields
        if ~isempty(StringFind(plosives, grams{i}, true))
            landmarks{i}.plosiveCenter = landmarks{i}.startPlosion + round((landmarks{i}.stopPlosion-landmarks{i}.startPlosion) / 2); %important that this rounds .5 up
        end
    end
    
    landmarks{1}.startVowel = 1; %for compatability with LandmarkDetectorSpeechmark()
    
    %% safety checks
    assert(ceil(landmarks{end}.stopPhon) <= size(spec, 1));
    for i = 1:numel(landmarks)
        if i == 1
            assert(landmarks{i}.stopPhon > 2);
        else
            assert(landmarks{i}.stopPhon > landmarks{i-1}.stopPhon + 2);
        end
        
        if isfield(landmarks{i}, 'startPlosion')
            assert(landmarks{i}.startPlosion <= landmarks{i}.stopPlosion);
            if i > 1
                assert(landmarks{i}.startPlosion > landmarks{i-1}.stopPhon);
            end
            assert(landmarks{i}.stopPlosion <= landmarks{i}.stopPhon);
        elseif isfield(landmarks{i}, 'startFriction')
            assert(landmarks{i}.startFriction + 1 < landmarks{i}.stopFriction);
            if i > 1
                assert(landmarks{i}.startFriction > landmarks{i-1}.stopPhon);
            end
            assert(landmarks{i}.stopFriction <= landmarks{i}.stopPhon);
        end
    end
    
    %% multiply by 128 to convert to discrete time sample units
    for i = 1:numel(landmarks) %for each gram
        fields = fieldnames(landmarks{i});
        for j = 1:numel(fields)
            landmarks{i}.(fields{j}) = landmarks{i}.(fields{j}) * 128;
        end
    end
end
