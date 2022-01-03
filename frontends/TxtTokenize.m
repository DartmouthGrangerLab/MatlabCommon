% Eli Bowen
% 12/3/2021
% this will take a long while
% INPUTS:
%   text - (char)
%   dictionary - 1 x n_unique_words (cell array of chars)
%   tokenDefinition - (char) - regex defining a token e.g. '\w+' = [a-zA-Z_0-9] or '\S+' (word = nonwhitespace) (newlines always included as id = -1)
% RETURNS:
%   tokenIdx - 1 x n_words_in_text (int-valued numeric)
function [tokenIdx] = TxtTokenize (text, dictionary, tokenDefinition)
    validateattributes(text,            'char', {'nonempty'});
    validateattributes(dictionary,      'cell', {'nonempty'});
    validateattributes(tokenDefinition, 'char', {'nonempty'});
    n_threads = min(16, DetermineNumJavaComputeCores()); % too many and we run out of memory
%     n_threads = 1;

    t = tic();
    nlIdx = find(text == newline()); % must split things up to save memory
    n_nl_per_thread = ceil(numel(nlIdx) / n_threads);
    jobText     = cell(1, n_threads); % job input
    jobTokenIdx = cell(1, n_threads); % job output
    for job = 1 : n_threads
        temp1 = (job-1)*n_nl_per_thread + 1;
        temp2 = (job-1)*n_nl_per_thread + min(numel(nlIdx) - (job-1)*n_nl_per_thread, n_nl_per_thread+1);
        disp(['job ',num2str(job),': ',num2str(temp1),' --> ',num2str(temp2)]);
        jobText{job} = text(nlIdx(temp1):nlIdx(temp2));
        
        assert(text(nlIdx(temp1)) == newline() && text(nlIdx(temp2)) == newline());
        assert(jobText{job}(1) == newline() && jobText{job}(end) == newline());
    end
    clearvars nlIdx; % short on memory usually
    
    if n_threads == 1
        tokenIdx = Helper(dictionary, tokenDefinition, jobText{1}, true);
    else
        StartThreadPool(n_threads, false);
        parfor job = 1 : n_threads
            jobTokenIdx{job} = Helper(dictionary, tokenDefinition, jobText{job}, job == 1);
        end
        tokenIdx = cell2mat(jobTokenIdx);
    end

    toc(t)
end


function [tokenIdx] = Helper (dictionary, tokenDefinition, text, verbose)
    nlIdx = find(text == newline()); % must split things up to save memory
    n_lines = numel(nlIdx) - 1; % should be a new line at the start and the end
    
    tokenCnt = zeros(1, n_lines);
    for ln = 1 : n_lines
        tokenCnt(ln) = numel(regexp(text(nlIdx(ln)+1:nlIdx(ln+1)-1), tokenDefinition));

        if verbose && mod(ln, 1000000) == 0
            disp(['pre-processed ',num2str(ln/n_lines*100),'% of lines']);
        end
    end
    n_tokens = numel(nlIdx) + sum(tokenCnt);
    
    tokenIdx = NaN(1, n_tokens);
    
    dictionary = containers.Map(dictionary, 1:numel(dictionary));

    t = tic();
    count = 1;
    for ln = 1 : n_lines
        line = text(nlIdx(ln)+1:nlIdx(ln+1)-1);

        [startIdx,stopIdx] = regexp(line, tokenDefinition); % find first and last idx of each token

        tokenIdx(count) = -1; % -1 = newline
        count = count + 1;
        for i = 1 : numel(startIdx) % for each word
            if dictionary.isKey(line(startIdx(i):stopIdx(i)))
                tokenIdx(count) = dictionary(line(startIdx(i):stopIdx(i)));
            end
            % above same as below, but 100x faster (uses a map instead of a cell array)
%             idx = StringFind(dictionary, line(startIdx(i):stopIdx(i)), true);
%             if numel(idx) == 1
%                 tokenIdx(count) = idx;
%             end
            count = count + 1; % regardless of whether we set tokenIdx(count)
        end

        if verbose && mod(ln, 100000) == 0
            disp(['processed ',num2str(ln/n_lines*100),'% of lines in ',num2str(toc(t)),' s']);
        end
    end
    tokenIdx(count) = -1; % -1 = newline
    count = count + 1;
end