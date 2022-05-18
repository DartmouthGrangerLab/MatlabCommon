% arithmetic decoding
% downloaded from http://www.mathworks.com/matlabcentral/fileexchange/36377-arithmetic-encoding---decoding
% heavily modified by Eli Bowen 11/2015
% INPUTS
%   symbols - n_symbols x 1 (?) a string of symbols of information from the source
%   p       - n_symbols x 1 (numeric) the array of probabilities of the corresponding symbols in the SYM string
%   tagword - the bit-string that represents the tag value encoded by arithmetic coding
% RETURNS
%   decoded_seq
function decoded_seq = ArithmeticDecode(symbols, p, tagword)
    assert(length(symbols) == length(p) && sum(p) == 1, 'symbols / p params are incorrect');
    
%     precision = 100000000;

    %% Calculate the symbol intervals
    Fx = zeros(1, length(symbols));
    for i = 1 : length(symbols)
        if i == 1
            Fx(i) = p(i);
        else
            Fx(i) = Fx(i-1) + p(i);
        end
    end
%     Fx = vpa(Fx,precision);
    Fx = sym(Fx);

    %% Extract the length of sequence from the TAG WORD
    %seq_len = bin2dec(tagword(length(tagword)-15:length(tagword)));
    split_code = strsplit(tagword, ','); % coded_symbols,'|',sequencelength
    tagword = split_code{1};
    seq_len = bin2dec(split_code{2});

    %% Decode the symbols
%     L = 0; U = 1; % initial lower and upper limits of the interval
%     L = vpa(0,precision); U = vpa(1,precision); % initial lower and upper limits of the interval
    L = sym(0); U = sym(1); % initial lower and upper limits of the interval
    %tagvalue = bin2dec_long(tagword) / 2^length(tagword);
%     tagvalue = vpa(bin2dec_long(tagword),precision) / vpa(2,precision)^vpa(length(tagword),precision);
    tagvalue = sym(bin2dec_long(tagword)) / (sym(2)^sym(length(tagword)));
    decoded_seq = [];
    for i = 1 : seq_len
        for j = 1 : length(symbols)
            try
                if eval(Fx(j) > (tagvalue-L)/(U-L))
                    decoded_seq = [decoded_seq,symbols(j)];
                    if j == 1
                        L_new = L;
                    else
                        L_new = L+(U-L)*Fx(j-1);
                    end
                    U_new = L+(U-L)*Fx(j);
                    break
                end
            catch
                error('String is too long to be represented using this implementation of arithmetic encoding');
            end
        end
        L = L_new;
        U = U_new;
    end
end