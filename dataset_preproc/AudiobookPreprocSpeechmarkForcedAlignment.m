% Eli Boewn
% 5/26/2018
% INPUTS:
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocSpeechmarkForcedAlignment (data)
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocSpeechmarkForcedAlignment...');
    t = tic();

    if isfield(data, 'word_audio') && isfield(data, 'word_phonetic') % we might not have phonetic spellings, e.g. if this is a foreign language
        %[vowel_segments,vowel_landmarks,consonant_landmarks,pt,pv,env,envv,vf,tvv] = vowel_segs_full(wordAudio{i}(1+0.5*fs:end), fs, maxf0_std('i'), 0, 'child');
        maxF0Std = maxf0_std('M');

        startPhon2 = zeros(numel(data.word_phonetic), 1);
        startPhon3 = zeros(numel(data.word_phonetic), 1);
        stopPhon3  = zeros(numel(data.word_phonetic), 1); % stopPhon3 only populated for vowels
        for i = 1:numel(data.word_phonetic)
            if isempty(data.word_phonetic{i})
                continue;
            end
            
            vowelInFlankers = ~isempty(regexp(data.word_phonetic{i}, '^\w\w\d \w{1,2} \w\w\d', 'ONCE'));
            vowelInMiddle = ~isempty(regexp(data.word_phonetic{i}, '^\w{1,2} \w\w\d ', 'ONCE')); % else vowels are the flankers
            if ~vowelInFlankers && ~vowelInMiddle
                continue;
            end
            try
%                 [vowelSegments,vowel_landmarks,consonant_landmarks,pt,pv,env,envv,vf,tvv] = vowel_segs_full(wordset.wordAudio{i}, data.sample_rate, maxf0_std('M'), [], 'adult');
                vowelSegments = vowel_segs_full(data.word_audio{i}, data.sample_rate, maxF0Std, [], 'adult');
            catch
                disp(['error in vowel_segs_full() for i=',num2str(i)]);
                vowelSegments = [];
            end
            % speechmark is so fucking inconsistent in it's return types...
            if size(vowelSegments, 2) > 0 && ~isnan(vowelSegments(1,1))
                vowelSegments(:,vowelSegments(2,:)==Inf) = [];
                if size(vowelSegments, 2) > 0 && size(vowelSegments, 1) == 3
                    vowelSegments(:,vowelSegments(3,:)<0) = []; % negative weights are non-voiced vowel segments, e.g. whispers, and are more likely to be errors than anything else in this data
                    if size(vowelSegments, 2) > 0 && size(vowelSegments, 1) == 3
                        if size(vowelSegments, 2) > 1
                            keepers = false(size(vowelSegments, 2), 1);
                            for j = 1:size(vowelSegments, 2)
                                duplicates = find(vowelSegments(1,:) == vowelSegments(1,j));
                                [~,idx] = max(vowelSegments(3,duplicates)); % if multiple vowel periods start at the same time, take the most probable one
                                keepers(duplicates(idx)) = true;
                            end
                            vowelSegments = vowelSegments(:,keepers);
                        end
                        if vowelInMiddle
                            vowelSegments(:,vowelSegments(1,:) > 0.3 | vowelSegments(2,:) < 0.096) = []; % loose bounds on reasonable ranges
                            if size(vowelSegments, 2) > 0
                                startPhon2(i) = ceil(vowelSegments(1,1) * data.sample_rate);
                                startPhon3(i) = ceil(vowelSegments(2,1) * data.sample_rate);
                                % leave stopPhon3 as zero
                            end
                        else
                            if size(vowelSegments, 2) > 1 % need, yaknow, 2 vowels
                                vowelSegments(:,vowelSegments(1,:)-vowelSegments(2,1) > 0.3) = []; % loose bounds on reasonable range
                                if size(vowelSegments, 2) > 2 % too many. need to pick two.
%                                     [~,keeperIdx] = max(vowelSegments(3,:)); % take the most probable one
                                    keeperIdx = 1;
                                    overlaps = ((vowelSegments(1,keeperIdx) > vowelSegments(1,:) & vowelSegments(2,:)+0.005 > vowelSegments(1,keeperIdx)) |... %if an entry starts earlier and overlaps
                                                (vowelSegments(1,keeperIdx) <= vowelSegments(1,:) & vowelSegments(2,keeperIdx)+0.005 > vowelSegments(1,:)));   %if an entry starts later and overlaps
                                    vowelSegments(3,overlaps) = -Inf; % can't select these for the second
                                    disp(['overlaps for ',data.word_phonetic{i},':']);
                                    disp(vowelSegments);
                                    if all(vowelSegments(3,:)==-Inf)
                                        vowelSegments = vowelSegments(:,keeperIdx); % there's only one valid vowel
                                    else
%                                         [~,idx] = max(vowelSegments(3,:));
                                        idx = find(vowelSegments(3,:)>-Inf, 1, 'first');
                                        vowelSegments = vowelSegments(:,[keeperIdx,idx]);
                                    end
                                end
                                if size(vowelSegments, 2) > 1 % if we found 2 valid ones
                                    if vowelSegments(2,1)+0.005 < vowelSegments(1,2) % if there's room for a consonant between them
                                        startPhon2(i) = ceil(vowelSegments(2,1) * data.sample_rate); % end of first vowel
                                        startPhon3(i) = ceil(vowelSegments(1,2) * data.sample_rate); % start of second vowel
                                        stopPhon3(i)  = ceil(vowelSegments(2,2) * data.sample_rate); % start of second vowel
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        data.word_speechmarks = struct('startPhon2', startPhon2, 'startPhon3', startPhon3, 'stopPhon3', stopPhon3);
    end
    toc(t)
end