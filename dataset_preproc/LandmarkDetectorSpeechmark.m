%Eli Bowen
%5/21/2018
%INPUTS:
%   wordAudio - audio stream (1d array of PCM) from word start to word end
%   wordPhonetic - string of the phonetic spelling of the word
%   startPhon2 - same as input, but refined based on detected landmarks
%   startPhon3 - same as input, but refined based on detected landmarks
%   stopPhon3 - OPTIONAL same as input, but refined based on detected landmarks. may be 0, [], or omitted to say "dunno"
%RETURNS:
%   landmarks - cell array of structs, one per gram (landmarks{2} are landmarks for gram 2)
function [landmarks] = LandmarkDetectorSpeechmark (wordAudio, wordPhonetic, startPhon2, startPhon3, stopPhon3)
    grams = strsplit(wordPhonetic, ' ');
    grams = regexprep(grams, '\d', '');
    
    plosives = {'P','T','K','D','G','B'}; %plosives PTK are voiceless, BDG are unaspirated
    fricatives = {'S','SH','Z','ZH','TH','DH','V','HH','F','CH','JH'}; %fricatives HH only kinda sorta counts. Couldn't quickly find documentation on CH or JH
    other = {'M','N','NG','R','L','W','Y'}; %other
    vowels = {'AA',...                        %original - "ra/la"
          'IY','IH','EY','EH',...             %vowels used by McClelland's lab
          'AE','AH','AO','UW','AY','AW',...   %other handy vowels, sorted roughly by descending usefulness (by looking at countsTrn)
          'OW','UH',...                       %other less handy vowels to consider
          'ER','OY'};                         %other vowels I don't like because they're similar to consonants
    
    if ~exist('stopPhon3', 'var') || isempty(stopPhon3)
        stopPhon3 = 0;
    end
    
    if ~(...
        (~isempty(StringFind(vowels, grams{1}, true)) && isempty(StringFind(vowels, grams{2}, true)) && ~isempty(StringFind(vowels, grams{3}, true))) ||...
        (isempty(StringFind(vowels, grams{1}, true)) && ~isempty(StringFind(vowels, grams{2}, true)) && isempty(StringFind(vowels, grams{3}, true)))...
        )
        warning('off', 'backtrace');
        warning(['currently only alternating vowels and consonants are supported for speechmark, so skipping [',grams{1},' ',grams{2},' ',grams{3},']']);
        warning('on', 'backtrace');
        landmarks = [];
        return;
    end

    spec = CalculateSpectrogram4Frontend(FeatureTransformAudio(wordAudio, 32000, 3, 128), 'power', 3);
    if stopPhon3 ~= 0
        spec = spec(1:min(round(stopPhon3/128)+50, end),:); %no single gram should take longer than this (50*128/32000=200ms) (but some words are long and complex, like "gobbldygook")
    else
        spec = spec(1:min(round(startPhon3/128)+100, end),:); %no single gram should take longer than this (50*128/32000=200ms) (but some words are long and complex, like "gobbldygook")
    end
    
%                                 power = abs(hilbert(trnWords4Use{i}.wordAudio{j}));
%                                 power = power(1:end-mod(numel(power), 128));
%                                 power = reshape(power, 128, numel(power)/128);
%                                 power = mean(power, 1);
    sumPowerMostFreqs = sum(spec(:,3:end), 2);
    sumPowerMostFreqs = smooth(sumPowerMostFreqs, 5, 'moving');
    sumPowerDiffMostFreqs = sumPowerMostFreqs(2:end)-sumPowerMostFreqs(1:end-1);
    sumPowerDiffMostFreqs = sumPowerDiffMostFreqs ./ max(abs(sumPowerDiffMostFreqs));

    sumPowerVoiceFreqs = sum(spec(:,1:5), 2);
    sumPowerVoiceFreqs = smooth(sumPowerVoiceFreqs, 5, 'moving');

    sumPowerLowerFreqs = sum(spec(:,5:end/4), 2);
    sumPowerLowerFreqs = smooth(sumPowerLowerFreqs, 3, 'moving');

    sumPowerMiddleFreqs = sum(spec(:,5:end/2), 2);
    sumPowerMiddleFreqs = smooth(sumPowerMiddleFreqs, 5, 'moving');

    sumPowerUpperFreqs = sum(spec(:,end/2:end), 2);
    sumPowerUpperFreqs = smooth(sumPowerUpperFreqs, 3, 'moving');
    sumPowerDiffUpperFreqs = sumPowerUpperFreqs(2:end)-sumPowerUpperFreqs(1:end-1);
    sumPowerDiffUpperFreqs = sumPowerDiffUpperFreqs ./ max(abs(sumPowerDiffUpperFreqs));

    %unused
%     corrMiddleFreqs = zeros(size(spec, 1)-1, 1);
%     for t = 1:size(spec, 1)-1
%         corrMiddleFreqs(t) = corr(spec(t,5:end/2)', spec(t+1,5:end/2)');
%     end
%     corrMiddleFreqs = smooth(corrMiddleFreqs, 3, 'moving');
%     corrMiddleFreqs = corrMiddleFreqs - min(corrMiddleFreqs);
%     corrMiddleFreqs = corrMiddleFreqs ./ max(corrMiddleFreqs);

    landmarks = cell(3, 1);
    landmarks{1} = struct();
    landmarks{2} = struct();
    landmarks{3} = struct();
    landmarks{1}.stopPhon = max(3, round(startPhon2/128) - 1);
    landmarks{2}.stopPhon = max(landmarks{1}.stopPhon + 3, round(startPhon3/128) - 1);
    landmarks{3}.stopPhon = max(landmarks{2}.stopPhon + 3, round(stopPhon3/128));
    if landmarks{3}.stopPhon > size(spec, 1)
        landmarks{3}.stopPhon = size(spec, 1);
        landmarks = Verify3TimeptsInGram(landmarks, 3);
    end

    %% special case of vow-other-vow (many errors in the vowe_segs_full code, where one vowel should be split into e.g. ah-r-ah
    if ~isempty(StringFind(other, grams{2}, true)) && landmarks{1}.stopPhon >= 15
        isAboveHalf = (sumPowerMiddleFreqs > max(sumPowerMiddleFreqs)/2);
        chunks = cumsum(isAboveHalf(2:landmarks{1}.stopPhon)~=isAboveHalf(3:landmarks{1}.stopPhon+1)) + 1; %+1 to get from zero-based to 1-based indexing
        isAboveHalf = isAboveHalf(3:landmarks{1}.stopPhon+1);
        uniqueChunks = unique(chunks);
        counts2 = CountNumericOccurrences(chunks, uniqueChunks);
        potentialChunks = find(counts2 > 5);
        if ~isempty(potentialChunks)
            potentialChunks(1) = [];
        end
        if ~isempty(potentialChunks)
            potentialChunks(end) = [];
        end
        potentialChunksBelowHalf = [];
        for chunkNum = 1:numel(potentialChunks)
            if ~isAboveHalf(find(chunks==potentialChunks(chunkNum), 1))
                potentialChunksBelowHalf = [potentialChunksBelowHalf,potentialChunks(chunkNum)];
            end
        end
        if numel(potentialChunksBelowHalf) == 1
            winningChunk = potentialChunksBelowHalf;
            vowelShift = find(sumPowerMiddleFreqs(landmarks{1}.stopPhon+1:landmarks{3}.stopPhon) < max(sumPowerMiddleFreqs)/2, 1, 'first');
            if isempty(vowelShift)
                landmarks{3}.stopPhon = landmarks{1}.stopPhon + 1;
            else
                landmarks{3}.stopPhon = landmarks{1}.stopPhon + vowelShift;
            end
            landmarks{1}.stopPhon = 2 + find(chunks==winningChunk, 1, 'first'); %2+ because of 3:landmarks{1}.stopPhon+1 above
            landmarks{2}.stopPhon = max(landmarks{1}.stopPhon+3, 2 + find(chunks==winningChunk, 1, 'last')); %2+ because of 3:landmarks{1}.stopPhon+1 above
        end
    end

    %% gram 1 find the landmarks
    if ~isempty(StringFind(plosives, grams{1}, true))
        [~,landmarks{1}.startPlosion] = max(sumPowerDiffMostFreqs(1:landmarks{1}.stopPhon+ceil((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)));
%         [~,landmarks{1}.stopPlosion] = min(sumPowerDiffMostFreqs(startPlosion+1:ceil((trnWords4Use{i}.startPhon2(j)+(trnWords4Use{i}.startPhon3(j)-trnWords4Use{i}.startPhon2(j))/2)/128)));
%         landmarks{1}.stopPlosion = landmarks{1}.stopPlosion + landmarks{1}.startPlosion;
        try
            [peakVals,peakIdxs] = findpeaks(-sumPowerDiffMostFreqs(landmarks{1}.startPlosion+1:end));
        catch %often fails because we only passed it 2 timepoints
            peakVals = [];
            peakIdxs = [];
        end
        peakIdxs(peakVals < -0.2) = []; %want only peaks that are less than zero. remember peakVals is -sumPowerDiffMostFreqs, so remove peakVals<0 not >0
        peakIdxs(peakIdxs+landmarks{1}.startPlosion > landmarks{2}.stopPhon-4) = [];
        if isempty(peakIdxs)
            landmarks{1}.stopPlosion = landmarks{1}.startPlosion + 2;
        else
            landmarks{1}.stopPlosion = landmarks{1}.startPlosion + peakIdxs(1); %first local minimum <0 after startPlosion
        end
        if landmarks{1}.stopPhon <= landmarks{1}.stopPlosion
            landmarks{1}.stopPhon = landmarks{1}.stopPlosion + 1;
        end
    elseif ~isempty(StringFind(fricatives, grams{1}, true))
        landmarks{1}.startFriction = find(sumPowerUpperFreqs(1:landmarks{1}.stopPhon+ceil((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)) > max(sumPowerUpperFreqs)*0.5, 1, 'first');
        if isempty(landmarks{1}.startFriction)
            [~,landmarks{1}.startFriction] = max(sumPowerDiffUpperFreqs(1:landmarks{1}.stopPhon+ceil((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)));
            landmarks{1}.startFriction = max(1, landmarks{1}.startFriction - 1);
        end
%         landmarks{1}.stopFriction = find(sumPowerUpperFreqs(landmarks{1}.startFriction+1:end) < max(sumPowerUpperFreqs)*0.5, 1, 'first');
        landmarks{1}.stopFriction = find(sumPowerUpperFreqs(landmarks{1}.startFriction+1:end) < sumPowerLowerFreqs(landmarks{1}.startFriction+1:end), 1, 'first'); %where the blue and pink lines cross
        if isempty(landmarks{1}.stopFriction) || landmarks{1}.stopFriction == 1
            landmarks{1}.stopFriction = max(landmarks{1}.stopPhon, landmarks{1}.startFriction+2);
        else
            landmarks{1}.stopFriction = landmarks{1}.startFriction + landmarks{1}.stopFriction;
        end
        if landmarks{1}.stopFriction > landmarks{1}.stopPhon + floor((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)
            landmarks{1}.stopFriction = landmarks{1}.stopPhon + floor((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2);
        end
%         landmarks{1}.stopFriction = landmarks{1}.stopPhon;
%         if landmarks{1}.startFriction + 3 <= numel(sumPowerDiffUpperFreqs)
%             [peakVals,peakIdxs] = findpeaks(-sumPowerDiffUpperFreqs(landmarks{1}.startFriction+1:end));
%             peakIdxs(peakVals<0) = []; %want only peaks that are less than zero. remember peakVals is -sumPowerDiffMostFreqs, so remove peakVals<0 not >0
%             peakIdxs(sumPowerUpperFreqs(peakIdxs)>threshold | sumPowerUpperFreqs(peakIdxs+1)>threshold) = []; %don't want peaks in delta when the absolute value is still super high
%             if ~isempty(peakIdxs)
%                 landmarks{1}.stopFriction = peakIdxs(1) + landmarks{1}.startFriction; %first local minimum <0 after startPlosion
%             end
%         end
        earlierStart = find(sumPowerUpperFreqs(1:landmarks{1}.startFriction) < max(sumPowerUpperFreqs)*0.25, 1, 'last');
        if isempty(earlierStart)
            landmarks{1}.startFriction = 1;
        elseif earlierStart < landmarks{1}.startFriction
            landmarks{1}.startFriction = earlierStart;
        end
        landmarks{1}.stopPhon = landmarks{1}.stopFriction; %move second gram (a vowel) to right here
    elseif ~isempty(StringFind(other, grams{1}, true))

    elseif ~isempty(StringFind(vowels, grams{1}, true))
        %shift start forward if there's forrealz silence at the start
        landmarks{1}.startVowel = find(sumPowerMiddleFreqs(1:landmarks{1}.stopPhon-2) > max(sumPowerMiddleFreqs)*0.2, 1, 'first');
        if isempty(landmarks{1}.startVowel)
            landmarks{1}.startVowel = 1;
        end
    end
    
    %for some reason not needed right now
%     if landmarks{1}.stopPhon < 3
%         landmarks{1}.stopPhon = 3;
%         landmarks = Verify3TimeptsInGram(landmarks, 1);
%     end

    %% gram 2 find the landmarks
    if ~isempty(StringFind(plosives, grams{2}, true))
        [~,landmarks{2}.startPlosion] = max(sumPowerDiffMostFreqs(floor(landmarks{1}.stopPhon/2)+1:ceil(landmarks{2}.stopPhon)));
        landmarks{2}.startPlosion = floor(landmarks{1}.stopPhon/2) + landmarks{2}.startPlosion;
        try
            [peakVals,peakIdxs] = findpeaks(-sumPowerDiffMostFreqs(landmarks{2}.startPlosion+1:end));
        catch %often fails because we only passed it 2 timepoints
            peakVals = [];
            peakIdxs = [];
        end
        peakIdxs(peakVals < -0.2) = []; %want only peaks that are less than zero. remember peakVals is -sumPowerDiffMostFreqs, so remove peakVals<0 not >0
        if landmarks{3}.stopPhon ~= 0
            peakIdxs(peakIdxs+landmarks{2}.startPlosion > landmarks{3}.stopPhon-4) = [];
        end
        if isempty(peakIdxs)
            landmarks{2}.stopPlosion = landmarks{2}.startPlosion + 2;
        else
            landmarks{2}.stopPlosion = landmarks{2}.startPlosion + peakIdxs(1); %first local minimum <0 after startPlosion
        end
        if landmarks{1}.stopPhon >= landmarks{2}.startPlosion
            landmarks{1}.stopPhon = landmarks{2}.startPlosion - 1;
        end
        %because there's a quiet segment in plosives, we can safely extend the vowel (if needed)
        vowelShift = find(sumPowerMiddleFreqs(landmarks{1}.stopPhon+1:landmarks{2}.startPlosion-1) < max(sumPowerMiddleFreqs)/2, 1, 'first');
        if ~isempty(vowelShift)
            landmarks{1}.stopPhon = landmarks{1}.stopPhon + vowelShift;
        end
        if landmarks{2}.stopPhon <= landmarks{2}.stopPlosion
            landmarks{2}.stopPhon = landmarks{2}.stopPlosion + 1;
        end
    elseif ~isempty(StringFind(fricatives, grams{2}, true))
        if strcmp(grams{2}, 'V')
            %we can't really improve on their vowel boundaries in this case (without new code)
            landmarks{2}.startFriction = landmarks{1}.stopPhon + 1;
            landmarks{2}.stopFriction = landmarks{2}.stopPhon;
        else
            [~,frictionPeak] = max(sumPowerUpperFreqs(floor(landmarks{1}.stopPhon/2)+2:ceil(landmarks{2}.stopPhon - 1 + (landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2)));
            frictionPeak = floor(landmarks{1}.stopPhon/2) + frictionPeak;
            startFricA = find(sumPowerDiffUpperFreqs(floor(landmarks{1}.stopPhon/2)+1:frictionPeak-1) <= 0, 1, 'last');
            startFricB = find(sumPowerUpperFreqs(floor(landmarks{1}.stopPhon/2)+1:frictionPeak-1) < max(sumPowerUpperFreqs)*0.5, 1, 'last');
            if isempty(startFricA)
                landmarks{2}.startFriction = frictionPeak-1;
            elseif ~isempty(startFricA) && isempty(startFricB)
                landmarks{2}.startFriction = floor(landmarks{1}.stopPhon/2) + startFricA;
            elseif ~isempty(startFricA) && ~isempty(startFricB)
                landmarks{2}.startFriction = floor(landmarks{1}.stopPhon/2) + min(startFricA, startFricB);
            end
%             landmarks{2}.stopFriction = landmarks{2}.startFriction + max(2, find(sumPowerUpperFreqs(landmarks{2}.startFriction+1:end) < max(sumPowerUpperFreqs)*0.5, 1));
            landmarks{2}.stopFriction = find(sumPowerUpperFreqs(frictionPeak+1:ceil(landmarks{2}.stopPhon - 1 + (landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2)) < sumPowerLowerFreqs(frictionPeak+1:ceil(landmarks{2}.stopPhon - 1 + (landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2)), 1); %where the blue and pink lines cross
            if isempty(landmarks{2}.stopFriction) || landmarks{2}.stopFriction == 1
                landmarks{2}.stopFriction = max([landmarks{2}.stopPhon,frictionPeak+1,landmarks{2}.startFriction+2]);
            else
                landmarks{2}.stopFriction = landmarks{2}.stopFriction + frictionPeak;
            end
%             if landmarks{2}.stopFriction > landmarks{2}.stopPhon + (?-landmarks{2}.stopPhon)/2
%                 landmarks{2}.stopFriction = landmarks{2}.stopPhon + (?-landmarks{2}.stopPhon)/2;
%             end
%             if landmarks{2}.startFriction + 3 <= numel(sumPowerDiffUpperFreqs)
%                 [peakVals,peakIdxs] = findpeaks(-sumPowerDiffUpperFreqs(landmarks{2}.startFriction+1:end));
%                 peakIdxs(peakVals<0) = []; %want only peaks that are less than zero. remember peakVals is -sumPowerDiffMostFreqs, so remove peakVals<0 not >0
%                 peakIdxs(sumPowerUpperFreqs(peakIdxs)>max(sumPowerUpperFreqs)*2/3 | sumPowerUpperFreqs(peakIdxs+1)>max(sumPowerUpperFreqs)*2/3) = []; %don't want peaks in delta when the absolute value is still super high
%                 if ~isempty(peakIdxs)
%                     landmarks{2}.stopFriction = peakIdxs(1) + landmarks{2}.startFriction; %first local minimum <0 after startPlosion
%                 end
%             end
            if landmarks{1}.stopPhon >= landmarks{2}.startFriction
                landmarks{1}.stopPhon = landmarks{2}.startFriction - 1;
                landmarks{1}.stopPhon = max(3, landmarks{2}.startFriction - 1);
            elseif strcmp(grams{2}, 'DH') || strcmp(grams{2}, 'JH') || strcmp(grams{2}, 'CH') %fricatives that come with silence beforehand
                %we can safely extend the vowel (if needed)
                vowelShift = find(sumPowerMiddleFreqs(landmarks{1}.stopPhon+1:landmarks{2}.startFriction) < max(sumPowerMiddleFreqs)*0.5, 1, 'first');
                if ~isempty(vowelShift)
                    landmarks{1}.stopPhon = landmarks{1}.stopPhon + vowelShift;
                    if landmarks{1}.stopPhon >= landmarks{2}.startFriction
                         landmarks{1}.stopPhon = landmarks{2}.startFriction - 1;
                    end
                end
            end
            if landmarks{2}.stopFriction > landmarks{2}.stopPhon
                landmarks{2}.stopPhon = landmarks{2}.stopFriction; %delay third gram
            end
        end
    elseif ~isempty(StringFind(other, grams{2}, true))
        if strcmp(grams{2}, 'W')
            %define W region between two vowels as the region where voiced is high but blue/green is low
            newStart = find(sumPowerMiddleFreqs(floor(landmarks{1}.stopPhon/2)+1:ceil(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)-1) > max(sumPowerMiddleFreqs)*0.5 & sumPowerVoiceFreqs(floor(landmarks{1}.stopPhon/2)+1:ceil(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)-1) < max(sumPowerVoiceFreqs)*0.5, 1, 'last');
            if ~isempty(newStart)
                landmarks{1}.stopPhon = floor(landmarks{1}.stopPhon/2) + newStart;
            end
            newStop = find(sumPowerMiddleFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:ceil(landmarks{2}.stopPhon + (landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2)) > max(sumPowerMiddleFreqs)*0.5 & sumPowerVoiceFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:ceil(landmarks{2}.stopPhon + (landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2)) < max(sumPowerVoiceFreqs)*0.5, 1, 'first');
            if ~isempty(newStop)
                landmarks{2}.stopPhon = floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2) + newStop;
            end
        end
    elseif ~isempty(StringFind(vowels, grams{2}, true))

    end

    %% gram 3 find the landmarks
    if ~isempty(StringFind(plosives, grams{3}, true))
        try
            [peakVals,peakIdxs] = findpeaks(sumPowerDiffMostFreqs(landmarks{1}.stopPhon+floor((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:end));
        catch %often fails because we only passed it 2 timepoints
            peakVals = [];
            peakIdxs = [];
        end
        if ~isempty(peakIdxs) && sum(sumPowerDiffMostFreqs>0) > 0
            peakIdxs(peakVals < max(sumPowerDiffMostFreqs(sumPowerDiffMostFreqs>0))*0.5) = []; %want only big peaks
        end
        if ~isempty(peakIdxs)
            landmarks{3}.startPlosion = peakIdxs(1); %first local minimum after filtering
        else
            [~,landmarks{3}.startPlosion] = max(sumPowerDiffMostFreqs(landmarks{1}.stopPhon+floor((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:end));
        end
        landmarks{3}.startPlosion = landmarks{1}.stopPhon+floor((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2) + landmarks{3}.startPlosion;
        landmarks{3}.stopPlosion = numel(sumPowerDiffMostFreqs);
        if landmarks{3}.startPlosion + 3 <= numel(sumPowerDiffMostFreqs)
            try
                [peakVals,peakIdxs] = findpeaks(-sumPowerDiffMostFreqs(landmarks{3}.startPlosion+1:end));
            catch %often fails because we only passed it 2 timepoints
                peakVals = [];
                peakIdxs = [];
            end
            peakIdxs(peakVals<-0.2) = []; %want only peaks that are less than zero. remember peakVals is -sumPowerDiffMostFreqs, so remove peakVals<0 not >0
            if ~isempty(peakIdxs)
                landmarks{3}.stopPlosion = peakIdxs(1) + landmarks{3}.startPlosion; %first local minimum <0 after startPlosion
            end
        end
        %because there's a quiet segment in plosives, we can safely extend the vowel (if needed)
        vowelShift = find(sumPowerMiddleFreqs(landmarks{2}.stopPhon+1:landmarks{3}.startPlosion) < max(sumPowerMiddleFreqs)*0.5, 1, 'first');
        if ~isempty(vowelShift)
            landmarks{2}.stopPhon = landmarks{2}.stopPhon + vowelShift;
        end
        if landmarks{2}.stopPhon >= landmarks{3}.startPlosion
            landmarks{2}.stopPhon = landmarks{3}.startPlosion - 1;
            landmarks = Verify3TimeptsInGram(landmarks, 2);
        end
        landmarks{3}.stopPhon = max(landmarks{3}.stopPlosion + 2, landmarks{2}.stopPhon + 3);
    elseif ~isempty(StringFind(fricatives, grams{3}, true))
        if strcmp(grams{3}, 'V')
            %requires special handling
            landmarks{3}.startFriction = landmarks{2}.stopPhon + 1;
            vowelLength = numel(landmarks{1}.stopPhon+1:landmarks{2}.stopPhon);
            landmarks{3}.stopFriction = min(size(spec, 1), landmarks{2}.stopPhon + vowelLength);
        else
            landmarks{3}.startFriction = find(sumPowerUpperFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+2:end) > max(sumPowerUpperFreqs)*2/3, 1, 'first');
            if isempty(landmarks{3}.startFriction)
                [~,landmarks{3}.startFriction] = max(sumPowerDiffUpperFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:end));
                landmarks{3}.startFriction = max(1, landmarks{3}.startFriction - 1);
            end
            landmarks{3}.startFriction = floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2) + landmarks{3}.startFriction;

            stopFricA = find(sumPowerDiffUpperFreqs(landmarks{3}.startFriction+1:end) < 0, 1, 'first');
            stopFricB = find(sumPowerUpperFreqs(landmarks{3}.startFriction+1:end) < max(sumPowerUpperFreqs)*0.5, 1, 'first');
            if ~isempty(stopFricA) && ~isempty(stopFricB)
                landmarks{3}.stopFriction = landmarks{3}.startFriction + max([2,stopFricA,stopFricB]);
            elseif ~isempty(stopFricA) && isempty(stopFricB)
                landmarks{3}.stopFriction = landmarks{3}.startFriction + max(2, stopFricA);
            elseif isempty(stopFricA) && ~isempty(stopFricB)
                landmarks{3}.stopFriction = landmarks{3}.startFriction + max(2, stopFricB);
            else %both empty
                landmarks{3}.stopFriction = numel(sumPowerUpperFreqs);
            end
%             landmarks{3}.stopFriction = numel(sumPowerDiffUpperFreqs);
%             if landmarks{3}.startFriction + 3 <= numel(sumPowerDiffUpperFreqs)
%                 [peakVals,peakIdxs] = findpeaks(-sumPowerDiffUpperFreqs(landmarks{3}.startFriction+1:end));
%                 peakIdxs(peakVals<0) = []; %want only peaks that are less than zero. remember peakVals is -sumPowerDiffMostFreqs, so remove peakVals<0 not >0
%                 peakIdxs(sumPowerUpperFreqs(peakIdxs)>max(sumPowerUpperFreqs)*2/3 | sumPowerUpperFreqs(peakIdxs+1)>max(sumPowerUpperFreqs)*2/3) = []; %don't want peaks in delta when the absolute value is still super high
%                 if ~isempty(peakIdxs)
%                     landmarks{3}.stopFriction = peakIdxs(1) + landmarks{3}.startFriction; %first local minimum <0 after startPlosion
%                 end
%             end
            if landmarks{2}.stopPhon >= landmarks{3}.startFriction
                landmarks{2}.stopPhon = max(landmarks{1}.stopPhon + 3, landmarks{3}.startFriction - 1);
            elseif strcmp(grams{3}, 'DH') || strcmp(grams{3}, 'JH') || strcmp(grams{3}, 'CH') %fricatives that come with silence beforehand
                %we can safely extend the vowel (if needed)
                vowelShift = find(sumPowerMiddleFreqs(landmarks{2}.stopPhon+1:landmarks{3}.startFriction) < max(sumPowerMiddleFreqs)*0.5, 1, 'first');
                if ~isempty(vowelShift)
                    landmarks{2}.stopPhon = landmarks{2}.stopPhon + vowelShift;
                    if landmarks{2}.stopPhon >= landmarks{3}.startFriction
                         landmarks{2}.stopPhon = landmarks{3}.startFriction - 1;
                    end
                end
            end
        end
        landmarks{3}.stopPhon = max(landmarks{3}.stopFriction, landmarks{2}.stopPhon + 3);
    elseif ~isempty(StringFind(other, grams{3}, true))
        newEnd = find(sumPowerMiddleFreqs(landmarks{2}.stopPhon+1:end) < max(sumPowerMiddleFreqs)*0.5, 1, 'first');
        if isempty(newEnd)
            newEnd = size(spec, 1);
        else
            newEnd = landmarks{2}.stopPhon + newEnd;
        end
        landmarks{3}.stopOther = min([size(spec, 1),landmarks{2}.stopPhon + 50,max(landmarks{2}.stopPhon + 3, newEnd)]); %50 is an arbitrary max - "no way" this consonant is longer than that)
%       if numel(grams) > 3 && ~isempty(StringFind(plosives, grams{4}, true))
%           %TODO
%       end
        if strcmp(grams{3}, 'W')
            %define W region between two vowels as the region where voiced is high but blue/green is low
            newStart = find(sumPowerMiddleFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:landmarks{2}.stopPhon) > max(sumPowerMiddleFreqs)*0.5 & sumPowerVoiceFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:landmarks{2}.stopPhon) < max(sumPowerVoiceFreqs)*0.5, 1, 'last');
            if isempty(newStart)
                if all(sumPowerMiddleFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:landmarks{2}.stopPhon) < max(sumPowerMiddleFreqs)*0.5 & sumPowerVoiceFreqs(floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2)+1:landmarks{2}.stopPhon) > max(sumPowerVoiceFreqs)*0.5)
                    landmarks{2}.stopPhon = floor(landmarks{1}.stopPhon + (landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2);
                end
            else
                landmarks{2}.stopPhon = landmarks{1}.stopPhon + floor((landmarks{2}.stopPhon-landmarks{1}.stopPhon)/2) + newStart;
            end
            if numel(grams) > 3 && ~isempty(StringFind(vowels, grams{4}, true))
%                 newStop = find(sumPowerMiddleFreqs(floor(landmarks{2}.stopPhon)+3:end) > max(sumPowerMiddleFreqs)*0.5 | sumPowerVoiceFreqs(floor(landmarks{2}.stopPhon)+3:end) < max(sumPowerVoiceFreqs)*0.5, 1, 'first') - 1;
%                 if ~isempty(newStop)
%                     landmarks{3}.stopOther = floor(landmarks{2}.stopPhon) + 2 + newStop;
%                 end
                try
                    [peakVals,peakIdxs] = findpeaks(-sumPowerLowerFreqs(floor(landmarks{2}.stopPhon)+3:end));
                catch %often fails because we only passed it 2 timepoints
                    peakVals = [];
                    peakIdxs = [];
                end
                peakIdxs(-peakVals > max(sumPowerLowerFreqs)*0.5) = []; %want only peaks below .5
                peakIdxs(sumPowerVoiceFreqs(floor(landmarks{2}.stopPhon)+2+peakIdxs) < max(sumPowerVoiceFreqs)*0.5) = []; %want only voiced peaks
                if ~isempty(peakIdxs)
                    landmarks{3}.stopOther = floor(landmarks{2}.stopPhon) + 2 + peakIdxs(1); %first local minimum after filtering
                    %now climb the other side of the valley
                    newStop = find(sumPowerMiddleFreqs(floor(landmarks{3}.stopOther)+1:end) > max(sumPowerMiddleFreqs)*0.5 | sumPowerVoiceFreqs(floor(landmarks{3}.stopOther)+1:end) < max(sumPowerVoiceFreqs)*0.5, 1, 'first') - 1;
                    if ~isempty(newStop)
                        landmarks{3}.stopOther = floor(landmarks{3}.stopOther) + newStop;
                    end
                end
            end
        else
            %let's be generous
            if landmarks{3}.stopOther - landmarks{2}.stopPhon < 5 && landmarks{2}.stopPhon - landmarks{1}.stopPhon >= 10
                landmarks{2}.stopPhon = landmarks{3}.stopOther - 5;
            end
        end
        landmarks{3}.stopPhon = max(landmarks{3}.stopOther, landmarks{2}.stopPhon + 3);
    elseif ~isempty(StringFind(vowels, grams{3}, true))
        
    end
    
    if landmarks{3}.stopPhon > size(spec, 1)
        landmarks{3}.stopPhon = size(spec, 1);
        landmarks = Verify3TimeptsInGram(landmarks, 3);
    end
    
    %% gram 4
    if numel(grams) > 3
        if ~isempty(StringFind(vowels, grams{3}, true))
            if ~isempty(StringFind(plosives, grams{4}, true))
                try
                    [peakVals,peakIdxs] = findpeaks(sumPowerDiffMostFreqs(landmarks{2}.stopPhon+ceil((landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2):end));
                catch %often fails because we only passed it 2 timepoints
                    peakVals = [];
                    peakIdxs = [];
                end
                peakIdxs(peakVals < max(sumPowerDiffMostFreqs(sumPowerDiffMostFreqs>0))*0.5) = []; %want only big peaks
                if ~isempty(peakIdxs)
                    startPlosion = peakIdxs(1); %first local minimum after filtering
                else
                    [~,startPlosion] = max(sumPowerDiffMostFreqs(landmarks{2}.stopPhon+ceil((landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2):end));
                end
                startPlosion = startPlosion + landmarks{2}.stopPhon+ceil((landmarks{3}.stopPhon-landmarks{2}.stopPhon)/2)-1;
                %because there's a quiet segment in plosives, we can safely extend the vowel (if needed)
                vowelShift = find(sumPowerMiddleFreqs(landmarks{3}.stopPhon+1:startPlosion) < max(sumPowerMiddleFreqs)*0.5, 1, 'first');
                if ~isempty(vowelShift)
                    landmarks{3}.stopPhon = landmarks{3}.stopPhon + vowelShift;
                end
                if landmarks{3}.stopPhon >= startPlosion
                    landmarks{3}.stopPhon = startPlosion - 1;
                    landmarks = Verify3TimeptsInGram(landmarks, 3);
                end
            elseif ~isempty(StringFind(fricatives, grams{4}, true))

            elseif ~isempty(StringFind(other, grams{4}, true))

            elseif ~isempty(StringFind(vowels, grams{4}, true))

            end
        end
        if ~isempty(StringFind(other, grams{3}, true))
            if ~isempty(StringFind(plosives, grams{4}, true))

            elseif ~isempty(StringFind(fricatives, grams{4}, true))

            elseif ~isempty(StringFind(other, grams{4}, true))

            elseif ~isempty(StringFind(vowels, grams{4}, true))

            end
        end
    end
    
    %% clean-up
    if ~isempty(StringFind(other, grams{1}, true))
        if landmarks{1}.stopPhon < 3
            landmarks{1}.stopPhon = landmarks{2}.stopPhon / 2;
        end
    end
    if landmarks{2}.stopPhon + 3 > size(spec, 1) %must be at least 3 timepoints long (or we won't be able to sample 3 timepoints from it)
        landmarks{3}.stopPhon = size(spec, 1); %probably already is, but let's be sure
        landmarks{2}.stopPhon = landmarks{3}.stopPhon - 3;
        if landmarks{1}.stopPhon + 3 > landmarks{2}.stopPhon
            landmarks{1}.stopPhon = landmarks{2}.stopPhon - 3;
        end
    end
    landmarks = Verify3TimeptsInGram(landmarks, 1);
    landmarks = Verify3TimeptsInGram(landmarks, 2);
    landmarks = Verify3TimeptsInGram(landmarks, 3);
    landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 1);
    landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 2);
    landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 3);
    
    %% add extra fields
    for i = 1:numel(landmarks)
        if ~isempty(StringFind(plosives, grams{i}, true))
            landmarks{i}.plosiveCenter = landmarks{i}.startPlosion + round((landmarks{i}.stopPlosion-landmarks{i}.startPlosion) / 2); %important that this rounds .5 up
        end
        if i == 1
            landmarks{i}.startPhon = 1;
            if ~isempty(StringFind(vowels, grams{1}, true))
                landmarks{i}.startPhon = landmarks{i}.startVowel;
            end
        else
            landmarks{i}.startPhon = landmarks{i-1}.stopPhon + 1;
        end
    end
    
    %% safety checks
    assert(landmarks{1}.stopPhon > 2);
    assert(landmarks{2}.stopPhon > landmarks{1}.stopPhon + 2);
    assert(landmarks{3}.stopPhon > landmarks{2}.stopPhon + 2);
    assert(ceil(landmarks{3}.stopPhon) <= size(spec, 1));
    for i = 1:numel(landmarks)
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


function [landmarks] = Verify3TimeptsInGram (landmarks, gramNum)
    if gramNum == 1
        
    elseif gramNum == 2
        if landmarks{1}.stopPhon + 3 > landmarks{2}.stopPhon
            if isfield(landmarks{3}, 'startPlosion') && landmarks{2}.stopPhon >= 6
                %we favor leaving plosives alone, since they tend to have correct boundaries. shrink gram 1
                landmarks{1}.stopPhon = landmarks{2}.stopPhon - 3;
                landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 1);
            elseif isfield(landmarks{1}, 'startPlosion') && landmarks{3}.stopPhon - landmarks{1}.stopPhon >= 6
                %we favor leaving plosives alone, since they tend to have correct boundaries. shrink gram 3
                landmarks{2}.stopPhon = landmarks{1}.stopPhon + 3;
                landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 3);
            elseif landmarks{1}.stopPhon > landmarks{3}.stopPhon - landmarks{2}.stopPhon
                %if no plosives, just shrink the larger phoneme. shrink gram 1
                landmarks{1}.stopPhon = landmarks{2}.stopPhon - 3;
                landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 1);
            else
                %if no plosives, just shrink the larger phoneme. shrink gram 3
                landmarks{2}.stopPhon = landmarks{1}.stopPhon + 3;
                landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 3);
            end
        end
    elseif gramNum == 3
        if landmarks{2}.stopPhon + 3 > landmarks{3}.stopPhon
            landmarks{2}.stopPhon = landmarks{3}.stopPhon - 3;
            landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 2);
            
            if landmarks{1}.stopPhon + 3 > landmarks{2}.stopPhon
                landmarks{1}.stopPhon = landmarks{2}.stopPhon - 3;
                landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 1);
                landmarks = LandmarkDetectorVerifyInternalLandmarks(landmarks, 2);
            end
        end
    else
        error('unknown gramNum');
    end
end