%Eli Boewn
%11/7/2018
function [] = PreprocSpeechFAVE (path)
    disp('PreprocSpeechFAVE...');
    t = tic();
    if logical(exist(fullfile(path, 'wordsphonetic.mat'), 'file')) && logical(exist(fullfile(path, 'wordsmontrealforcedalignment.mat'), 'file')) && logical(exist(fullfile(path, 'wordaudio.mat'), 'file'))
        load(fullfile(path, 'wordsphonetic.mat'), 'wordsPhonetic');
        load(fullfile(path, 'wordsmontrealforcedalignment.mat'), 'wordsMontrealForcedAlignment');
        load(fullfile(path, 'wordaudio.mat'), 'wordAudio');
        
        %TODO: verify the below works great - is it a cell or numeric array?
%         wordDurations = cellfun(@numel, wordAudio); %duration in discrete timesteps
%         clearvars wordAudio;
        
        wordsFAVE = cell(numel(wordsPhonetic), 1);
        skipped = false(numel(wordsPhonetic), 1);
        for i = 1:1000:numel(wordsPhonetic)
            for j = i:min(i+999, numel(wordsPhonetic))
                countStr = sprintf(['%0',num2str(numel(num2str(numel(wordsPhonetic)))),'d'], j); %adds leading zeros (from SaveWavFiles)
                
                if isempty(wordsPhonetic{j}) || isempty(wordsMontrealForcedAlignment{j})
                    continue;
                end
                
                fileID = fopen(fullfile(path, 'FAVE', num2str(i), ['word_',countStr,'.txt']), 'r');
                if fileID == -1
                    warning(['cannot find alignment file ',fullfile(path, 'FAVE', num2str(i), ['word_',countStr,'.txt']),', skipping!']);
                    skipped(j) = true;
                    continue;
                end
                header = strsplit(fgetl(fileID), '\t', 'CollapseDelimiters', false);
                wordsFAVE{j} = struct();
                wordsFAVE{j}.vowel = {}; assert(strcmp(header{13}, 'vowel'));
                wordsFAVE{j}.stress = []; assert(strcmp(header{14}, 'stress'));
                wordsFAVE{j}.f1 = []; assert(strcmp(header{18}, 'F1'));
                wordsFAVE{j}.f2 = []; assert(strcmp(header{19}, 'F2'));
                wordsFAVE{j}.f3 = []; assert(strcmp(header{20}, 'F3'));
                wordsFAVE{j}.t = []; assert(strcmp(header{24}, 't'));
                wordsFAVE{j}.beg = []; assert(strcmp(header{25}, 'beg'));
                wordsFAVE{j}.end = []; assert(strcmp(header{26}, 'end'));
                wordsFAVE{j}.dur = []; assert(strcmp(header{27}, 'dur'));
                wordsFAVE{j}.plt_vclass = {}; assert(strcmp(header{28}, 'plt_vclass'));
                wordsFAVE{j}.plt_manner = {}; assert(strcmp(header{29}, 'plt_manner'));
                wordsFAVE{j}.plt_place = {}; assert(strcmp(header{30}, 'plt_place'));
                wordsFAVE{j}.plt_voice = {}; assert(strcmp(header{31}, 'plt_voice'));
                wordsFAVE{j}.plt_preseg = {}; assert(strcmp(header{32}, 'plt_preseg'));
                wordsFAVE{j}.plt_folseq = {}; assert(strcmp(header{33}, 'plt_folseq'));
                wordsFAVE{j}.style = {}; assert(strcmp(header{34}, 'style'));
                wordsFAVE{j}.glide = {}; assert(strcmp(header{35}, 'glide'));
                wordsFAVE{j}.pre_seg = {}; assert(strcmp(header{36}, 'pre_seg'));
                wordsFAVE{j}.fol_seg = {}; assert(strcmp(header{37}, 'fol_seg'));
                wordsFAVE{j}.context = {}; assert(strcmp(header{38}, 'context'));
                wordsFAVE{j}.vowel_index = []; assert(strcmp(header{39}, 'vowel_index'));
                wordsFAVE{j}.f1At20Percent = []; assert(strcmp(header{43}, 'F1@20%'));
                wordsFAVE{j}.f2At20Percent = []; assert(strcmp(header{44}, 'F2@20%'));
                wordsFAVE{j}.f1At35Percent = []; assert(strcmp(header{45}, 'F1@35%'));
                wordsFAVE{j}.f2At35Percent = []; assert(strcmp(header{46}, 'F2@35%'));
                wordsFAVE{j}.f1At50Percent = []; assert(strcmp(header{47}, 'F1@50%'));
                wordsFAVE{j}.f2At50Percent = []; assert(strcmp(header{48}, 'F2@50%'));
                wordsFAVE{j}.f1At65Percent = []; assert(strcmp(header{49}, 'F1@65%'));
                wordsFAVE{j}.f2At65Percent = []; assert(strcmp(header{50}, 'F2@65%'));
                wordsFAVE{j}.f1At80Percent = []; assert(strcmp(header{51}, 'F1@80%'));
                wordsFAVE{j}.f2At80Percent = []; assert(strcmp(header{52}, 'F2@80%'));
                wordsFAVE{j}.nFormants = []; assert(strcmp(header{53}, 'nFormants'));
                
                count = 1;
                while ~feof(fileID)
                    text = strsplit(fgetl(fileID), '\t', 'CollapseDelimiters', false);
                    assert(numel(text) == numel(header));
                    
                    wordsFAVE{j}.vowel{count} = text{13};
                    wordsFAVE{j}.stress(count) = str2double(text{14});
                    wordsFAVE{j}.f1(count) = str2double(text{18});
                    wordsFAVE{j}.f2(count) = str2double(text{19});
                    wordsFAVE{j}.f3(count) = str2double(text{20});
                    wordsFAVE{j}.t(count) = str2double(text{24});
                    wordsFAVE{j}.beg(count) = str2double(text{25});
                    wordsFAVE{j}.end(count) = str2double(text{26});
                    wordsFAVE{j}.dur(count) = str2double(text{27});
                    wordsFAVE{j}.plt_vclass{count} = text{28};
                    wordsFAVE{j}.plt_manner{count} = text{29};
                    wordsFAVE{j}.plt_place{count} = text{30};
                    wordsFAVE{j}.plt_voice{count} = text{31};
                    
                    %I dunno what these mean
                    wordsFAVE{j}.plt_preseg{count} = text{32};
                    wordsFAVE{j}.plt_folseq{count} = text{33};
                    wordsFAVE{j}.style{count} = text{34};
                    wordsFAVE{j}.glide{count} = text{35};
                    wordsFAVE{j}.pre_seg{count} = text{36};
                    wordsFAVE{j}.fol_seg{count} = text{37};
                    
                    wordsFAVE{j}.context{count} = text{38};
                    wordsFAVE{j}.vowel_index(count) = str2double(text{39});
                    wordsFAVE{j}.f1At20Percent(count) = str2double(text{43});
                    wordsFAVE{j}.f2At20Percent(count) = str2double(text{44});
                    wordsFAVE{j}.f1At35Percent(count) = str2double(text{45});
                    wordsFAVE{j}.f2At35Percent(count) = str2double(text{46});
                    wordsFAVE{j}.f1At50Percent(count) = str2double(text{47});
                    wordsFAVE{j}.f2At50Percent(count) = str2double(text{48});
                    wordsFAVE{j}.f1At65Percent(count) = str2double(text{49});
                    wordsFAVE{j}.f2At65Percent(count) = str2double(text{50});
                    wordsFAVE{j}.f1At80Percent(count) = str2double(text{51});
                    wordsFAVE{j}.f2At80Percent(count) = str2double(text{52});
                    wordsFAVE{j}.nFormants(count) = str2double(text{53});
                    count = count + 1;
                end
                fclose(fileID);
                
                %convert from units of seconds to samples (@32khz)
                wordsFAVE{j}.t   = max(1, floor(wordsFAVE{j}.t .* 32000));
                wordsFAVE{j}.beg = max(1, floor(wordsFAVE{j}.beg .* 32000));
                wordsFAVE{j}.end = max(1, floor(wordsFAVE{j}.end .* 32000));
                wordsFAVE{j}.dur = max(1, floor(wordsFAVE{j}.dur .* 32000));
                
                %we zero-padded each clip in ExtractWords4MontrealForcedAligner()
                wordsFAVE{j}.t   = wordsFAVE{j}.t - 32000*0.1;
                wordsFAVE{j}.beg = wordsFAVE{j}.beg - 32000*0.1;
                wordsFAVE{j}.end = wordsFAVE{j}.end - 32000*0.1;
                wordsFAVE{j}.dur = wordsFAVE{j}.dur - 32000*0.1;
                
                lengthOfClip = numel(wordAudio{j});
                wordsFAVE{j}.t   = min(lengthOfClip, wordsFAVE{j}.t);
                wordsFAVE{j}.beg = min(lengthOfClip, wordsFAVE{j}.beg);
                wordsFAVE{j}.end = min(lengthOfClip, wordsFAVE{j}.end);
                wordsFAVE{j}.dur = min(lengthOfClip, wordsFAVE{j}.dur);
                
                %ensure phonemes match up with the phonetic spellings of the words
                splitWordPhonetic = strsplit(wordsPhonetic{j});
                for k = 1:numel(wordsFAVE{j}.vowel)
                    assert(strcmp(regexprep(splitWordPhonetic{wordsFAVE{j}.vowel_index(k)}, '\d', ''), wordsFAVE{j}.vowel{k}));
                end
                
                %TODO: check for bad phonemes
            end
        end
        
        disp(['could not find FAVE results files for ',num2str(sum(skipped)/numel(skipped)*100),'% (',num2str(sum(skipped)),') of words']);
        
        save(fullfile(path, 'wordsfave.mat'), 'wordsFAVE', '-v7.3', '-nocompression');
    end
    toc(t)
end
