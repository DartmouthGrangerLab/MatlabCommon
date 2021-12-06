% Eli Bowen
% 12/3/2021
% INPUTS:
%   text - (char)
%   dictionary - 1 x n_unique_words (cell array of chars)
%   tokenDefinition - (char) - regex defining a token e.g. '\w+' = [a-zA-Z_0-9] or '(\S+|\n)' (word = nonwhitespace or newline)
% RETURNS:
%   tokenIdx - 1 x n_words_in_text (int-valued numeric)
function [tokenIdx] = TxtTokenize (text, dictionary, tokenDefinition)
    validateattributes(text,            'char', {'nonempty'});
    validateattributes(dictionary,      'cell', {'nonempty'});
    validateattributes(tokenDefinition, 'char', {'nonempty'});

    % find first and last idx of each token
    [startIdx,stopIdx] = regexp(text, tokenDefinition);

    tokenIdx = zeros(1, numel(startIdx));
    for i = 1 : numel(startIdx) % for each word
        if text(startIdx) == newline()
            tokenIdx(i) = -1;
        else
            idx = StringFind(dictionary, text(startIdx(i):stopIdx(i)), true);
            if numel(idx) == 1
                tokenIdx(i) = idx;
            elseif numel(idx) == 0
                tokenIdx(i) = NaN;
            else
                error('found duplicate words in dictionary');
            end
        end
    end
end