% INPUTS
%   coded_seq
%   codewords
%   symbols
% RESULT
%   decoded_seq
function decoded_seq = HuffmanDecode(coded_seq, codewords, symbols)
    M = length(codewords);
    decoded_seq = [];
    
    symInd = 1;
    while symInd < numel(coded_seq)
        lcs = length(coded_seq) - symInd + 1;
        for m = 1 : M
            codeword = codewords{m};
            lc = length(codeword);
            if lcs >= lc && codeword == coded_seq(symInd:symInd+lc-1)
                symbol = symbols(m);
                break
            end
            symbol = '?';
        end
        decoded_seq = [decoded_seq,symbol];
        symInd = symInd + lc;
    end

    % SLOW method
%     while ~isempty(coded_seq)
%         lcs = length(coded_seq);
% %         is_found = false;
%         for m = 1 : M
%             codeword = codewords{m};
%             lc = length(codeword);
%             if lcs >= lc && codeword == coded_seq(1:lc)
%                 symbol = symbols(m);
% %                 is_found = true;
%                 break
%             end
% %             if ~is_found
%                 symbol = '?';
% %             end
%         end
%         decoded_seq = [decoded_seq,symbol];
%         coded_seq = coded_seq(lc+1:end);
%     end
end