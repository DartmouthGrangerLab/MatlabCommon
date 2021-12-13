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
    n_threads = min(8, DetermineNumJavaComputeCores()); % too many and we run out of memory

    t = tic();
    nlIdx = find(text == newline()); % must split things up to save memory
    n_lines = numel(nlIdx) - 1; % should be a new line at the start and the end
    
    tokenCnt = zeros(1, n_lines);
    for ln = 1 : n_lines
        tokenCnt(ln) = numel(regexp(text(nlIdx(ln)+1:nlIdx(ln+1)-1), tokenDefinition));

        if mod(ln, 1000000) == 0
            disp(['pre-processed ',num2str(ln),' lines (',num2str(ln/n_lines*100),'%)']);
        end
    end
    n_tokens = numel(nlIdx) + sum(tokenCnt);
    toc(t)

    t = tic();
    jobNewlineStartIdx = zeros(1, n_threads);
    jobNewlineStopIdx  = zeros(1, n_threads);
    jobText            = cell(1, n_threads);
    jobTokenCnt        = zeros(1, n_threads);
    jobLineCnt         = zeros(1, n_threads);
    jobTokenIdx        = cell(1, n_threads); % job output
    for job = 1 : n_threads
        temp1 = (job-1)*ceil(numel(nlIdx)/n_threads) + 1;
        temp2 = (job-1)*ceil(numel(nlIdx)/n_threads) + min(numel(nlIdx) - (job-1)*ceil(numel(nlIdx)/n_threads), ceil(numel(nlIdx)/n_threads)+1);
        disp(['job ',num2str(job),': ',num2str(temp1),'---',num2str(temp2)]);
        jobNewlineStartIdx(job) = nlIdx(temp1);
        jobNewlineStopIdx(job) = nlIdx(temp2);
        jobText{job} = text(jobNewlineStartIdx(job):jobNewlineStopIdx(job));
        jobTokenCnt(job) = sum(tokenCnt(temp1:min(n_lines, temp2-1)));
        jobLineCnt(job) = numel(temp1:temp2) - 1;
        
        assert(text(jobNewlineStartIdx(job)) == newline());
        assert(text(jobNewlineStopIdx(job)) == newline());
        assert(jobText{job}(1) == newline() && jobText{job}(end) == newline());
    end
    assert(sum(jobTokenCnt) == (n_tokens-numel(nlIdx)));
    assert(sum(jobLineCnt) == n_lines);

    if n_threads > 1
        StartThreadPool(n_threads, false);
        parfor job = 1 : n_threads
            jobTokenIdx{job} = Helper(dictionary, tokenDefinition, jobNewlineStartIdx(job), jobNewlineStopIdx(job), jobText{job}, jobTokenCnt(job), jobLineCnt(job));
        end
    else
        for job = 1 : n_threads
            jobTokenIdx{job} = Helper(dictionary, tokenDefinition, jobNewlineStartIdx(job), jobNewlineStopIdx(job), jobText{job}, jobTokenCnt(job), jobLineCnt(job));
        end
    end

    tokenIdx = cell2mat(jobTokenIdx);
    assert(numel(tokenIdx) == n_tokens);
    toc(t)

%     tokenIdx = NaN(1, n_tokens);
%     count = 1;
%     for ln = 1 : n_lines
%         line = text(nlIdx(ln)+1:nlIdx(ln+1)-1);
%         
%         [startIdx,stopIdx] = regexp(line, tokenDefinition); % find first and last idx of each token
% 
%         tokenIdx(count) = -1; % -1 = newline
%         count = count + 1;
%         for i = 1 : numel(startIdx) % for each word
%             idx = StringFind(dictionary, line(startIdx(i):stopIdx(i)), true);
%             if numel(idx) == 1
%                 tokenIdx(count) = idx;
%             end
%             count = count + 1; % regardless of whether we set tokenIdx(count)
%         end
%         
%         if mod(ln, 1000000) == 0
%             disp(['processed ',num2str(ln),' lines (',num2str(ln/n_lines*100),'%)']);
%         end
%     end
%     tokenIdx(count) = -1; % -1 = newline
%     count = count + 1;
end


function [tokenIdx] = Helper (dictionary, tokenDefinition, newlineStartIdx, newlineStopIdx, text, tokenCnt, lineCnt)
    tokenIdx = NaN(1, tokenCnt);
    newlineIdx = newlineStartIdx:newlineStopIdx;

    count = 1;
    for ln = 1 : lineCnt
        line = text(newlineIdx(ln)+1:newlineIdx(ln+1)-1);

        [startIdx,stopIdx] = regexp(line, tokenDefinition); % find first and last idx of each token

        tokenIdx(count) = -1; % -1 = newline
        count = count + 1;
        for i = 1 : numel(startIdx) % for each word
            idx = StringFind(dictionary, line(startIdx(i):stopIdx(i)), true);
            if numel(idx) == 1
                tokenIdx(count) = idx;
            end
            count = count + 1; % regardless of whether we set tokenIdx(count)
        end

        if mod(ln, 100000) == 0
            disp(['processed ',num2str(ln/lineCnt*100),'% of lines']);
        end
    end
    tokenIdx(count) = -1; % -1 = newline
    count = count + 1;
end