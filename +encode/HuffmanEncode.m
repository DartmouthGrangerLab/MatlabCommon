% copied and modified from: http://www.mathworks.com/matlabcentral/fileexchange/26384-ppt-for-chapter-9-of--matlab-simulink-for-digital-communication-
% INPUTS
%   src
%   symbols
%   codewords
% RESULT
%   coded_seq
function coded_seq = HuffmanEncode(src, symbols, codewords)
    n_symbols = length(symbols);
    if length(codewords) < n_symbols
        error('the number of codewords must equal that of symbols');
    end

    coded_seq = [];
    for n = 1 : length(src)
        is_found = false;
        for i = 1 : n_symbols
            if src(n) == symbols(i)
                tmp = codewords{i};
                is_found = true;
                break
            end
        end
        if ~is_found
            tmp = '?';
        end
        coded_seq = [coded_seq,tmp];
    end
end