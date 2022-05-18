% INPUTS
%   p       - M x 1 (numeric) probability of each symbol
%   do_flip - OPTIONAL scalar (logical)
% RETURNS
%   h - (cell array of chars)
%   L - scalar (numeric) average code word length
%   H - scalar (numeric) entropy
function [h,L,H] = HuffmanCodeGenerator(p, do_flip)
    p = p(:);
    assert(abs(sum(p)-1) <= 1e-6, 'the probabilities in p must add up to 1');

    M = length(p);
    N = M - 1;

    zero_one = '01';
    if nargin > 1 && do_flip
        zero_one = '10';
    end
    h = {zero_one(1),zero_one(2)};

    if M > 2
        pp(:,1) = p;
        for n = 1 : N
            % to sort in decending order
            [pp(1:M-n+1,n),o(1:M-n+1,n)] = sort(pp(1:M-n+1,n), 1, 'descend');
            if n == 1
                ord0 = o; % ordinal descending order
            end
            if M-n > 1
                pp(1:M-n,n+1) = [pp(1:M-1-n,n);sum(pp(M-n:M-n+1,n))];
            end
        end
        for n = N:-1:2
            tmp = N - n + 2;
            oi = o(1:tmp,n);
            for i = 1 : tmp
                h1{oi(i)} = h{i};
            end
            h = h1;
            h{tmp+1} = h{tmp};
            h{tmp} = [h{tmp},zero_one(1)];
            h{tmp+1} = [h{tmp+1},zero_one(2)];
        end
        for i = 1 : length(ord0)
            h1{ord0(i)} = h{i};
        end
        h = h1;
    end

    % average code word length
    L = 0;
    for n = 1 : M
        L = L + p(n) * length(h{n});
    end
%     L = sum(p .* cellfun(@numel, h{n})); % faster but untested

    % entropy
    H = -sum(p .* log2(p));
end