% deprecated 
function [NMI,MI] = NMI2 (true_mem, mem)
    if nargin == 1
        T = true_mem; %contingency table pre-supplied
    elseif nargin == 2
        %added by Eli Bowen 4/8/2017 for safety
        assert(isvector(true_mem) && isvector(mem) && numel(true_mem)==numel(mem), 'With 2 arguments, both arguments must be 1D and of equal length');
        assert(min(true_mem) > 0 && min(mem) > 0, 'Category IDs must be > 0');
        
        %build the contingency table from membership arrays
        R = max(true_mem);
        C = max(mem);

        %identify & removing the missing labels
        list_t = ismember(1:R, true_mem);
        list_m = ismember(1:C, mem);
        T = Contingency(true_mem, mem);
        T = T(list_t, list_m);
    end

    N = sum(sum(T));
    
    %update the true dimensions
    [R,C] = size(T);
    if C > 1
        a = sum(T');
    else
        a = T';
    end
    if R > 1
        b = sum(T);
    else
        b = T;
    end

    %calculating the Entropies
    Ha = -(a/N) * log(a/N)'; 
    Hb = -(b/N) * log(b/N)';

    %calculate the MI (unadjusted)
    MI = 0;
    for i = 1:R
        for j = 1:C
            if T(i,j) > 0
                MI = MI + T(i,j) * log(T(i,j)*N/(a(i)*b(j)));
            end
        end
    end
    MI = MI / N;
    if MI == 0
        NMI = 0;
    else
        NMI = MI / sqrt(Ha*Hb);
    end
end

%---------------------auxiliary functions---------------------
function [Cont] = Contingency (Mem1, Mem2)
    if nargin < 2 || min(size(Mem1)) > 1 || min(size(Mem2)) > 1
        error('Contingency: Requires two vector arguments');
    end

    Cont = zeros(max(Mem1), max(Mem2));

    for i = 1:length(Mem1);
        Cont(Mem1(i),Mem2(i)) = Cont(Mem1(i),Mem2(i)) + 1;
    end
end

            