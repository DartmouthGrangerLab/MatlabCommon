% arithmetic coding using the incremental encoding technique
% downloaded from http://www.mathworks.com/matlabcentral/fileexchange/36377-arithmetic-encoding---decoding
% heavily modified by Eli Bowen 11/2015
% INPUTS
%	symbols - n_symbols x 1 (?) a string of symbols of information from the source
%	p       - n_symbols x 1 (numeric) the array of Probabilities of the corresponding symbols in the SYM string
%	src     - the string of sequence of symbols to be encoded by arithmetic coding
% RETURNS
%   tag_bits
function tag_bits = ArithmeticEncode(symbols, p, src)
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

    %% Encode the sequence of symbols
%     L = 0; U = 1; % initial lower and upper intervals
%     L = vpa(0,precision); U = vpa(1,precision); % initial lower and upper intervals
    L = sym(0); U = sym(1); % initial lower and upper intervals
%     point5 = vpa(0.5,precision); % for efficiency
%     one = vpa(1,precision); % for efficiency
%     two = vpa(2,precision); % for efficiency
    point5 = sym(0.5); % for efficiency
    one = sym(1); % for efficiency
    two = sym(2); % for efficiency
    tag_bits = zeros(1, 0);
    for i = 1 : length(src)
        j = find(src(i) == symbols); % finds the index of the sequence symbol in the symbol string
        if j == 1
            L_new = L;
        else
            L_new = L + (U-L)*Fx(j-1);
        end
        U_new = L + (U-L)*Fx(j);
        L = L_new;
        U = U_new;
        while (eval(L < point5) && eval(U < point5)) || (eval(L >= point5) && eval(U > point5))
            if eval(L < point5) && eval(U < point5)
                tag_bits = [tag_bits,'0'];
                L = two * L;
                U = two * U;
            else
                tag_bits = [tag_bits,'1'];
                L = two * (L-point5);
                U = two * (U-point5);
            end
        end
    end
    tag = (L+U) / two;

    %% Embed the final tag value
    bits = zeros(1, 0);
    if eval(two*tag > one)
        tag = two*tag - one;
        bits = [bits,'1'];
    else
        tag = two*tag;
        bits = [bits,'0'];
    end

    while eval(sym(bin2dec_long(bits))/two^sym(length(bits)) < L)
%     while vpa(bin2dec_long(bits),precision)/two^vpa(length(bits),precision) < L
%     while bin2dec_long(bits)/2^length(bits) < L
        if eval(two*tag > one)
            tag = two*tag - one;
            bits = [bits,'1'];
        else
            tag = two*tag;
            bits = [bits,'0'];
        end
    end
    tag_bits = [tag_bits,bits];

    %% Padding of zeros is done to keep the TAG BITS size a multiple of 16 bits
    tag_bits = [tag_bits,dec2bin(0,16-rem(length(tag_bits),16))];
%     disp('Tag Value is:');
%     disp(bin2dec(tag_bits)/2^length(tag_bits));
%     disp('Tag Word is:');

    %% Append sequence length (16 bits)
    seqLength = dec2bin(length(src));
    tag_bits = [tag_bits,',',seqLength];
end