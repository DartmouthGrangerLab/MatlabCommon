%Eli Boewn
%5/26/2018
function [] = PreprocSpeechSpeechmarkForcedAlignment (path)
    disp('PreprocSpeechSpeechmarkForcedAlignment...');
    tic;    
    if logical(exist(fullfile(path, 'wordaudio.mat'), 'file')) && logical(exist(fullfile(path, 'wordsphonetic.mat'), 'file')) %we might not have phonetic spellings, e.g. if this is a foreign language
        load(fullfile(path, 'wordaudio.mat'), 'wordAudio');
        load(fullfile(path, 'wordsphonetic.mat'), 'wordsPhonetic');

        %[vowel_segments,vowel_landmarks,consonant_landmarks,pt,pv,env,envv,vf,tvv] = vowel_segs_full(wordAudio{i}(1+0.5*fs:end), fs, maxf0_std('i'), 0, 'child');
        fs = 32000;
        maxF0Std = maxf0_std('M');

        startPhon2 = zeros(numel(wordsPhonetic), 1);
        startPhon3 = zeros(numel(wordsPhonetic), 1);
        stopPhon3 = zeros(numel(wordsPhonetic), 1); %stopPhon3 only populated for vowels
        for i = 1:numel(wordsPhonetic)
            if isempty(wordsPhonetic{i})
                continue;
            end
            
            vowelInFlankers = ~isempty(regexp(wordsPhonetic{i}, '^\w\w\d \w{1,2} \w\w\d', 'ONCE'));
            vowelInMiddle = ~isempty(regexp(wordsPhonetic{i}, '^\w{1,2} \w\w\d ', 'ONCE')); %else vowels are the flankers
            if ~vowelInFlankers && ~vowelInMiddle
                continue;
            end
            try
%                 [vowelSegments,vowel_landmarks,consonant_landmarks,pt,pv,env,envv,vf,tvv] = vowel_segs_full(wordset.wordAudio{i}, fs, maxf0_std('M'), [], 'adult');
                vowelSegments = vowel_segs_full(wordAudio{i}, fs, maxF0Std, [], 'adult');
            catch
                disp(['error in vowel_segs_full() for i=',num2str(i)]);
                vowelSegments = [];
            end
            %speechmark is so fucking inconsistent in it's return types...
            if size(vowelSegments, 2) > 0 && ~isnan(vowelSegments(1,1))
                vowelSegments(:,vowelSegments(2,:)==Inf) = [];
                if size(vowelSegments, 2) > 0 && size(vowelSegments, 1) == 3
                    vowelSegments(:,vowelSegments(3,:)<0) = []; %negative weights are non-voiced vowel segments, e.g. whispers, and are more likely to be errors than anything else in this data
                    if size(vowelSegments, 2) > 0 && size(vowelSegments, 1) == 3
                        if size(vowelSegments, 2) > 1
                            keepers = false(size(vowelSegments, 2), 1);
                            for j = 1:size(vowelSegments, 2)
                                duplicates = find(vowelSegments(1,:) == vowelSegments(1,j));
                                [~,idx] = max(vowelSegments(3,duplicates)); %if multiple vowel periods start at the same time, take the most probable one
                                keepers(duplicates(idx)) = true;
                            end
                            vowelSegments = vowelSegments(:,keepers);
                        end
                        if vowelInMiddle
                            vowelSegments(:,vowelSegments(1,:) > 0.3 | vowelSegments(2,:) < 0.096) = []; %loose bounds on reasonable ranges
                            if size(vowelSegments, 2) > 0
                                startPhon2(i) = ceil(vowelSegments(1,1)*fs);
                                startPhon3(i) = ceil(vowelSegments(2,1)*fs);
                                %leave stopPhon3 as zero
                            end
                        else
                            if size(vowelSegments, 2) > 1 %need, yaknow, 2 vowels
                                vowelSegments(:,vowelSegments(1,:)-vowelSegments(2,1) > 0.3) = []; %loose bounds on reasonable range
                                if size(vowelSegments, 2) > 2 %too many. need to pick two.
%                                     [~,keeperIdx] = max(vowelSegments(3,:)); %take the most probable one
                                    keeperIdx = 1;
                                    overlaps = ((vowelSegments(1,keeperIdx) > vowelSegments(1,:) & vowelSegments(2,:)+0.005 > vowelSegments(1,keeperIdx)) |... %if an entry starts earlier and overlaps
                                                (vowelSegments(1,keeperIdx) <= vowelSegments(1,:) & vowelSegments(2,keeperIdx)+0.005 > vowelSegments(1,:)));   %if an entry starts later and overlaps
                                    vowelSegments(3,overlaps) = -Inf; %can't select these for the second
                                    disp(['overlaps for ',wordsPhonetic{i},':']);
                                    disp(vowelSegments);
                                    if all(vowelSegments(3,:)==-Inf)
                                        vowelSegments = vowelSegments(:,keeperIdx); %there's only one valid vowel
                                    else
%                                         [~,idx] = max(vowelSegments(3,:));
                                        idx = find(vowelSegments(3,:)>-Inf, 1, 'first');
                                        vowelSegments = vowelSegments(:,[keeperIdx,idx]);
                                    end
                                end
                                if size(vowelSegments, 2) > 1 %if we found 2 valid ones
                                    if vowelSegments(2,1)+0.005 < vowelSegments(1,2) %if there's room for a consonant between them
                                        startPhon2(i) = ceil(vowelSegments(2,1)*fs); %end of first vowel
                                        startPhon3(i) = ceil(vowelSegments(1,2)*fs); %start of second vowel
                                        stopPhon3(i) = ceil(vowelSegments(2,2)*fs); %start of second vowel
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        wordSpeechmarks = struct('startPhon2', startPhon2, 'startPhon3', startPhon3, 'stopPhon3', stopPhon3);
        save(fullfile(path, 'wordspeechmarks.mat'), 'wordSpeechmarks', '-v7.3', '-nocompression');
    end
    toc
end
