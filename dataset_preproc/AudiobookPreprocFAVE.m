% Eli Boewn
% 11/7/2018
% INPUTS:
%   path - (char) - data folder
%   data - dataset struct
% RETURNS:
%   data - dataset with new fields (old fields not modified)
function [data] = AudiobookPreprocFAVE (path, data)
    validateattributes(path, {'char'}, {'nonempty'});
    validateattributes(data, {'struct'}, {'nonempty','scalar'});

    disp('AudiobookPreprocFAVE...');
    t = tic();

    if isfield(data, 'word_phonetic') && isfield(data, 'word_montrealforcedalignment') && isfield(data, 'word_audio')
        %TODO: verify the below works great - is it a cell or numeric array?
%         wordDurations = cellfun(@numel, data.word_audio); % duration in discrete timesteps
        
        wordsFAVE = cell(numel(data.word_phonetic), 1);
        skipped = false(numel(data.word_phonetic), 1);
        for i = 1:1000:numel(data.word_phonetic)
            for j = i:min(i+999, numel(data.word_phonetic))
                countStr = sprintf(['%0',num2str(numel(num2str(numel(data.word_phonetic)))),'d'], j); % adds leading zeros (from SaveWavFiles)
                
                if isempty(data.word_phonetic{j}) || isempty(data.word_montrealforcedalignment{j})
                    continue;
                end
                
                if exist(fullfile(path, 'FAVE', num2str(i), ['word_',countStr,'.txt']), 'file') == 0
                    warning(['cannot find alignment file ',fullfile(path, 'FAVE', num2str(i), ['word_',countStr,'.txt']),', skipping!']);
                    skipped(j) = true;
                    continue;
                end
                wordsFAVE{j} = LoadFAVE(fullfile(path, 'FAVE', num2str(i), ['word_',countStr,'.txt']));
                
                % convert from units of seconds to samples (@32khz)
                wordsFAVE{j}.t   = max(1, floor(wordsFAVE{j}.t .* data.sample_rate));
                wordsFAVE{j}.beg = max(1, floor(wordsFAVE{j}.beg .* data.sample_rate));
                wordsFAVE{j}.end = max(1, floor(wordsFAVE{j}.end .* data.sample_rate));
                wordsFAVE{j}.dur = max(1, floor(wordsFAVE{j}.dur .* data.sample_rate));
                
                % we zero-padded each clip in ExtractWords4MontrealForcedAligner()
                wordsFAVE{j}.t   = wordsFAVE{j}.t - data.sample_rate*0.1;
                wordsFAVE{j}.beg = wordsFAVE{j}.beg - data.sample_rate*0.1;
                wordsFAVE{j}.end = wordsFAVE{j}.end - data.sample_rate*0.1;
                wordsFAVE{j}.dur = wordsFAVE{j}.dur - data.sample_rate*0.1;
                
                lengthOfClip = numel(data.word_audio{j});
                wordsFAVE{j}.t   = min(lengthOfClip, wordsFAVE{j}.t);
                wordsFAVE{j}.beg = min(lengthOfClip, wordsFAVE{j}.beg);
                wordsFAVE{j}.end = min(lengthOfClip, wordsFAVE{j}.end);
                wordsFAVE{j}.dur = min(lengthOfClip, wordsFAVE{j}.dur);
                
                % ensure phonemes match up with the phonetic spellings of the words
                splitWordPhonetic = strsplit(data.word_phonetic{j});
                for k = 1:numel(wordsFAVE{j}.vowel)
                    assert(strcmp(regexprep(splitWordPhonetic{wordsFAVE{j}.vowel_index(k)}, '\d', ''), wordsFAVE{j}.vowel{k}));
                end
                
                %TODO: check for bad phonemes
            end
        end
        
        disp(['could not find FAVE results files for ',num2str(sum(skipped)/numel(skipped)*100),'% (',num2str(sum(skipped)),') of words']);
        
        data.word_fave = wordsFAVE;
    end
    toc(t)
end