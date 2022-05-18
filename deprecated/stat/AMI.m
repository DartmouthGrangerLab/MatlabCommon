% deprecated
function [AMI_] = AMI (true_mem, mem, checkEMITooLow)
    if nargin == 1 || (nargin == 2 && isempty(mem))
        T = true_mem; %contingency table pre-supplied
    elseif nargin > 1
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
    if ~exist('checkEMITooLow', 'var') || isempty(checkEMITooLow)
        checkEMITooLow = true;
    end

    %-----------------------calculate Rand index and others----------
    N = sum(sum(T));
    C = T;
    nis = sum(sum(C, 2).^2);	%sum of squares of sums of rows
    njs = sum(sum(C, 1).^2);	%sum of squares of sums of columns

    t1 = nchoosek(N, 2);		%total number of pairs of entities
    t2 = sum(sum(C.^2));        %sum over rows & columnns of nij^2
    t3 = 0.5*(nis+njs);

    %Expected index (for adjustment)
    nc = (N*(N^2+1)-(N+1)*nis-(N+1)*njs+2*(nis*njs)/N) / (2*(N-1));

    A = t1 + t2 - t3;	%no. agreements
    D = -t2 + t3;		%no. disagreements

    if t1 == nc
       AR = 0;		%avoid division by zero; if k=1, define Rand = 0
    else
       AR = (A-nc) / (t1-nc); %adjusted Rand - Hubert & Arabie 1985
    end

    RI = A / t1;			%Rand 1971		%Probability of agreement
    MIRKIN = D / t1;	    %Mirkin 1970	%p(disagreement)
    HI = (A-D) / t1;      	%Hubert 1977	%p(agree)-p(disagree)
    Dri = 1 - RI;           %distance version of the RI
    Dari = 1 - AR;          %distance version of the ARI
    %-----------------------%calculate Rand index and others%----------

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

    %-------------correcting for agreement by chance---------------------------
    EPLNP = zeros(R, C);
    LogNij = log((1:min(max(a), max(b))) / N);
    for i = 1:R
        for j = 1:C
            nij = max(1, a(i)+b(j)-N);
            X = sort([nij N-a(i)-b(j)+nij]);
            if N-b(j) > X(2)
                nom = [[a(i)-nij+1:a(i)] [b(j)-nij+1:b(j)] [X(2)+1:N-b(j)]];
                dem = [[N-a(i)+1:N] [1:X(1)]];
            else
                nom = [[a(i)-nij+1:a(i)] [b(j)-nij+1:b(j)]];       
                dem = [[N-a(i)+1:N] [N-b(j)+1:X(2)] [1:X(1)]];
            end
            p0 = prod(nom./dem) / N;

            EPLNP(i,j) = nij * LogNij(nij) * p0;
            p1 = p0 * (a(i)-nij) * (b(j)-nij) / (nij+1) / (N-a(i)-b(j)+nij+1);  
            
            for nij = max(1, a(i)+b(j)-N) + 1:min(a(i), b(j))
                EPLNP(i,j) = EPLNP(i,j) + nij*LogNij(nij)*p1;
                p1 = p1 * (a(i)-nij) * (b(j)-nij) / (nij+1) / (N-a(i)-b(j)+nij+1);            
            end
        end
    end
    
    AB = a' * b; %a and b are vectors, so AB(i,j) = a(i) * b(j)
    E3 = (AB/N^2) .* log(AB/N^2);

    EMI = sum(sum(EPLNP-E3));

    AMI_ = (MI-EMI) / (max(Ha,Hb)-EMI);

    %If expected mutual information negligible, use NMI.
    if checkEMITooLow
        CC = zeros(R, C);
        for i = 1:R
            for j = 1:C
                CC(i,j) = N * (a(i)-1) * (b(j)-1) / AB(i,j) / (N-1) + N / AB(i,j);
            end
        end
        bound = AB .* log(CC) ./ N^2;
        EMI_bound = sum(sum(bound));
%         EMI_bound_2 = log(R*C/N+(N-R)*(N-C)/(N*(N-1)));

        if abs(EMI) < EMI_bound %Eli: fixed this by switching greater than to less than
            disp(['The EMI is small: EMI < ',num2str(EMI_bound),', setting AMI=NMI']);
            AMI_ = NMI;
        end
    end
end

%---------------------auxiliary functions---------------------
function [Cont] = Contingency (Mem1, Mem2)
    if nargin < 2 || min(size(Mem1)) > 1 || min(size(Mem2)) > 1
        error('Contingency: Requires two vector arguments');
    end

    Cont = zeros(max(Mem1), max(Mem2));

    for i = 1:length(Mem1)
        Cont(Mem1(i),Mem2(i)) = Cont(Mem1(i),Mem2(i)) + 1;
    end
end

            