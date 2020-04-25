%Eli Boewn
%11/7/2018
function [] = PreprocSpeechMontrealForcedAlignment (path)
    disp('PreprocSpeechMontrealForcedAlignment...');
    t = tic();
    if logical(exist(fullfile(path, 'wordsphonetic.mat'), 'file')) && logical(exist(fullfile(path, 'wordaudio.mat'), 'file'))
%         load(fullfile(path, 'words.mat'), 'words'); %TEMP
        load(fullfile(path, 'wordsphonetic.mat'), 'wordsPhonetic');
        load(fullfile(path, 'wordaudio.mat'), 'wordAudio');
        
        wordsMontrealForcedAlignment = cell(numel(wordsPhonetic), 1);
        remove = false(numel(wordsPhonetic), 1);
%         temp = {};
%         tempCount = 0;
        for i = 1:1000:numel(wordsPhonetic)
            for j = i:min(i+999, numel(wordsPhonetic))
                countStr = sprintf(['%0',num2str(numel(num2str(numel(wordsPhonetic)))),'d'], j); %adds leading zeros (from SaveWavFiles)
                
                fileID = fopen(fullfile(path, 'MontrealForcedAligner', num2str(i), ['word_',countStr,'.csv']), 'r');
                
                if fileID == -1
                    warning(['cannot find alignment file ',fullfile(path, 'MontrealForcedAligner', num2str(i), ['word_',countStr,'.csv']),', skipping!']);
                    continue;
                end
                header = strsplit(fgetl(fileID), ',', 'CollapseDelimiters', false);
                wordsMontrealForcedAlignment{j} = struct();
                wordsMontrealForcedAlignment{j}.phonemes = {};
                wordsMontrealForcedAlignment{j}.startTime = [];
                wordsMontrealForcedAlignment{j}.endTime = [];
                count = 1;
                while ~feof(fileID)
                    text = strsplit(fgetl(fileID), ',', 'CollapseDelimiters', false);
                    assert(numel(text) == numel(header));
                    if strcmp(text{4}, 'phones')
                        wordsMontrealForcedAlignment{j}.phonemes{count} = text{3};
                        wordsMontrealForcedAlignment{j}.startTime(count) = str2double(text{1});
                        wordsMontrealForcedAlignment{j}.endTime(count) = str2double(text{2});
                        count = count + 1;
                    end
                end
                fclose(fileID);
                
                %remove stress numbers when present
%                 wordsMontrealForcedAlignment{j}.phonemes = regexprep(wordsMontrealForcedAlignment{j}.phonemes, '\d', '');
                
                %montreal forced aligner seems to be in units of seconds (and input is required to be 32khz)
                wordsMontrealForcedAlignment{j}.startTime = floor(wordsMontrealForcedAlignment{j}.startTime .* 32000);
                wordsMontrealForcedAlignment{j}.endTime = floor(wordsMontrealForcedAlignment{j}.endTime .* 32000);
                
                %we zero-padded each clip in ExtractWords4MontrealForcedAligner()
                wordsMontrealForcedAlignment{j}.startTime = max(1, wordsMontrealForcedAlignment{j}.startTime - 32000*0.1);
                wordsMontrealForcedAlignment{j}.endTime = max(1, wordsMontrealForcedAlignment{j}.endTime - 32000*0.1);
                
                lengthOfClip = numel(wordAudio{j});
                wordsMontrealForcedAlignment{j}.startTime = min(lengthOfClip, wordsMontrealForcedAlignment{j}.startTime);
                wordsMontrealForcedAlignment{j}.endTime = min(lengthOfClip, wordsMontrealForcedAlignment{j}.endTime);
                
                %remove silence or noise phonemes
                badPhons = strcmp(wordsMontrealForcedAlignment{j}.phonemes, 'sil');
                badPhons = badPhons | strcmp(wordsMontrealForcedAlignment{j}.phonemes, 'sp');
                badPhons = badPhons | strcmp(wordsMontrealForcedAlignment{j}.phonemes, 'spn');
                wordsMontrealForcedAlignment{j}.phonemes(badPhons) = [];
                wordsMontrealForcedAlignment{j}.startTime(badPhons) = [];
                wordsMontrealForcedAlignment{j}.endTime(badPhons) = [];
                
%                 if isempty(wordsPhonetic{j}) && ~isempty(wordsMontrealForcedAlignment{j}.phonemes)
%                     tempCount = tempCount + 1;
%                     if isempty(StringFind(temp, words{j}, true))
%                         temp = [temp,words{j}];
%                         disp([num2str(tempCount/j * 100),'% (',num2str(numel(temp)),' unique): ',words{j},' (',num2str(j),')']);
%                     end
%                 end

                if isempty(wordsPhonetic{j}) || isempty(wordsMontrealForcedAlignment{j}.phonemes)
%                     disp(['removing word ',num2str(j),' because wordsPhonetic{',num2str(j),'} was empty']);
%                     disp(wordsMontrealForcedAlignment{j});
                    remove(j) = true;
                    continue;
                end
                
                splitWordPhonetic = strsplit(wordsPhonetic{j});
                assert(numel(wordsMontrealForcedAlignment{j}.phonemes) == numel(splitWordPhonetic));
                for k = 1:numel(wordsMontrealForcedAlignment{j}.phonemes)
                    assert(strcmp(wordsMontrealForcedAlignment{j}.phonemes{k}, splitWordPhonetic{k}));
                end
                
                %uh-oh if phonemes only occurred during the silence we tagged onto the beginning and end
                badPhons = (wordsMontrealForcedAlignment{j}.startTime==1 & wordsMontrealForcedAlignment{j}.endTime==1);
                badPhons = badPhons | (wordsMontrealForcedAlignment{j}.startTime==lengthOfClip & wordsMontrealForcedAlignment{j}.endTime==lengthOfClip);
                if any(badPhons)
                    disp(['removing word ',num2str(j),' because phonemes were bad']);
                    disp(wordsMontrealForcedAlignment{j});
                    remove(j) = true;
%                     h = figure();
%                     ImagescSpectrogram(CalculateSpectrogram4Frontend(FeatureTransformAudio(wordAudio{j}, 32000, 3, 128), 'power', 3), 3, true);
%                     currYLim = ylim();
%                     hold on;
%                     for k = 1:numel(wordsMontrealForcedAlignment{j}.endTime)
%                         plot([wordsMontrealForcedAlignment{j}.endTime(k)/128,wordsMontrealForcedAlignment{j}.endTime(k)/128], currYLim);
%                     end
%                     xlabel('time (sec)');
%                     currXLim = xlim();
%                     ax = gca();
%                     ax.XTick = 0:10:currXLim(2);
%                     ax.XTickLabel = (0:10:currXLim(2)) .* (128/32000); %128/32000ths of a second per sample
%                     ax.XMinorTick = 'on';
%                     ax.XAxis.MinorTickValues = 0:5:currXLim(2);
%                     close(h);
                end
            end
        end
        
        disp([num2str(sum(remove)/numel(remove)*100),'% (',num2str(sum(remove)),') of words will be removed because wordsPhonetic was empty or the Montreal Forced Aligner clearly failed']);
        wordsMontrealForcedAlignment(remove) = {[]};

        save(fullfile(path, 'wordsmontrealforcedalignment.mat'), 'wordsMontrealForcedAlignment', '-v7.3', '-nocompression');
    end
    toc(t)
end
