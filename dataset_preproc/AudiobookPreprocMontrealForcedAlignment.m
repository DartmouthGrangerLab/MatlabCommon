% Eli Boewn
% 11/7/2018
% INPUTS:
%   path - (char) - data folder
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocMontrealForcedAlignment (path, data)
    validateattributes(path, {'char'}, {'nonempty'});
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocMontrealForcedAlignment...');
    t = tic();

    if isfield(data, 'word_phonetic') && isfield(data, 'word_audio')
        wordMFA = cell(numel(data.word_phonetic), 1);
        remove = false(numel(data.word_phonetic), 1);
%         temp = {};
%         tempCount = 0;
        for i = 1:1000:numel(data.word_phonetic)
            for j = i:min(i+999, numel(data.word_phonetic))
                countStr = sprintf(['%0',num2str(numel(num2str(numel(data.word_phonetic)))),'d'], j); %adds leading zeros (from SaveWavFiles)

                if exist(fullfile(path, 'MontrealForcedAligner', num2str(i), ['word_',countStr,'.csv']), 'file') == 0
                    warning(['cannot find alignment file ',fullfile(path, 'MontrealForcedAligner', num2str(i), ['word_',countStr,'.csv']),', skipping!']);
                    continue;
                end

                wordMFA{j} = LoadMFA(fullfile(path, 'MontrealForcedAligner', num2str(i), ['word_',countStr,'.csv']));
                
                % remove stress numbers when present
%                 wordMFA{j}.phonemes = regexprep(wordMFA{j}.phonemes, '\d', '');
                
                % montreal forced aligner seems to be in units of seconds (and input is required to be 32khz)
                wordMFA{j}.startTime = floor(wordMFA{j}.startTime .* data.sample_rate);
                wordMFA{j}.endTime = floor(wordMFA{j}.endTime .* data.sample_rate);
                
                % we zero-padded each clip in ExtractWords4MontrealForcedAligner()
                wordMFA{j}.startTime = max(1, wordMFA{j}.startTime - data.sample_rate*0.1);
                wordMFA{j}.endTime = max(1, wordMFA{j}.endTime - data.sample_rate*0.1);
                
                lengthOfClip = numel(data.word_audio{j});
                wordMFA{j}.startTime = min(lengthOfClip, wordMFA{j}.startTime);
                wordMFA{j}.endTime = min(lengthOfClip, wordMFA{j}.endTime);
                
                %remove silence or noise phonemes
                badPhons = strcmp(wordMFA{j}.phonemes, 'sil');
                badPhons = badPhons | strcmp(wordMFA{j}.phonemes, 'sp');
                badPhons = badPhons | strcmp(wordMFA{j}.phonemes, 'spn');
                wordMFA{j}.phonemes(badPhons) = [];
                wordMFA{j}.startTime(badPhons) = [];
                wordMFA{j}.endTime(badPhons) = [];
                
%                 if isempty(data.word_phonetic{j}) && ~isempty(wordMFA{j}.phonemes)
%                     tempCount = tempCount + 1;
%                     if isempty(StringFind(temp, words{j}, true))
%                         temp = [temp,words{j}];
%                         disp([num2str(tempCount/j * 100),'% (',num2str(numel(temp)),' unique): ',words{j},' (',num2str(j),')']);
%                     end
%                 end

                if isempty(data.word_phonetic{j}) || isempty(wordMFA{j}.phonemes)
%                     disp(['removing word ',num2str(j),' because wordsPhonetic{',num2str(j),'} was empty']);
%                     disp(wordMFA{j});
                    remove(j) = true;
                    continue;
                end
                
                splitWordPhonetic = strsplit(data.word_phonetic{j});
                assert(numel(wordMFA{j}.phonemes) == numel(splitWordPhonetic));
                for k = 1:numel(wordMFA{j}.phonemes)
                    assert(strcmp(wordMFA{j}.phonemes{k}, splitWordPhonetic{k}));
                end
                
                % uh-oh if phonemes only occurred during the silence we tagged onto the beginning and end
                badPhons = (wordMFA{j}.startTime==1 & wordMFA{j}.endTime==1);
                badPhons = badPhons | (wordMFA{j}.startTime==lengthOfClip & wordMFA{j}.endTime==lengthOfClip);
                if any(badPhons)
                    disp(['removing word ',num2str(j),' because phonemes were bad']);
                    disp(wordMFA{j});
                    remove(j) = true;
%                     h = figure();
%                     ImagescSpectrogram(CalculateSpectrogram4Frontend(FeatureTransformAudio(data.word_audio{j}, data.sample_rate, 3, 128), 'power', 3), 3, true);
%                     currYLim = ylim();
%                     hold on;
%                     for k = 1:numel(wordMFA{j}.endTime)
%                         plot([wordMFA{j}.endTime(k)/128,wordMFA{j}.endTime(k)/128], currYLim);
%                     end
%                     xlabel('time (sec)');
%                     currXLim = xlim();
%                     ax = gca();
%                     ax.XTick = 0:10:currXLim(2);
%                     ax.XTickLabel = (0:10:currXLim(2)) .* (128/data.sample_rate); % 128/32000ths of a second per sample
%                     ax.XMinorTick = 'on';
%                     ax.XAxis.MinorTickValues = 0:5:currXLim(2);
%                     close(h);
                end
            end
        end
        
        disp([num2str(sum(remove)/numel(remove)*100),'% (',num2str(sum(remove)),') of words will be removed because wordsPhonetic was empty or the Montreal Forced Aligner clearly failed']);
        wordMFA(remove) = {[]};

        data.word_montrealforcedalignment = wordMFA;
    end
    toc(t)
end