% Eli Bowen 12/10/2021
% INPUTS:
%   tokenizedTxt - 1 x n_tokens (int-valued numeric)
%   dictionary   - 1 x n_unique_words (cell array of chars)
% RETURNS:
%   text - (char)
function text = Token2Txt(tokenizedTxt, dictionary)
    validateattributes(tokenizedTxt, {'numeric'}, {'nonempty'}, 1);
    validateattributes(dictionary, {'cell'}, {'nonempty'}, 2);

    dictionary{end+1} = newline();
    tokenizedTxt(tokenizedTxt == -1) = numel(dictionary);
    text = strjoin(dictionary(tokenizedTxt));
end