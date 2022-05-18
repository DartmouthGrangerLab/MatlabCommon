% deprecated
function [pValues] = fppermutationtest (G1Data, G2Data, simulate, permutations)
    validateattributes(G1Data, {'numeric'}, {'vector'}, 1);
    validateattributes(G2Data, {'numeric'}, {'vector'}, 2);
    validateattributes(simulate, {'logical','numeric'}, {'scalar'}, 3);
    G1Data = G1Data(:); %ensure column vector
    G2Data = G2Data(:); %ensure column vector

    %Revert to default number of permutations if unspecified
    if nargin == 3
        permutations = 50000;
    end

    %Initialise variables
    N(1) = numel(G1Data);
    N(2) = numel(G2Data);
    n = sum(N);

    if simulate == 1    
        [~, idx] = sort(rand(n, permutations), 1);
        Allocation = idx <= N(1);
    else 
        permutations = nchoosek(n, N(1));

        if permutations > 1000000
            check = input(['Running with ',num2str(permutations) ,' permutations. Continue? [Y/N]: '],'s');
            if check =='N'
                pValues = [];
                return
            end
        end

        D = 0:ones(1,n)*pow2(n-1:-1:0)';
        b = rem(floor(pow2(1-n:0)'*D),2);
        Allocation = logical(b(:,sum(b,1) == N(1)));
    end

    % Compute the statistic for all the permutations
    DataMatrix = [G1Data;G2Data]';

    StatDist = DataMatrix*Allocation/N(1) - DataMatrix*(~Allocation)/N(2);
    absStatDist = abs(StatDist);

    % Critical value for given allocation
    critvalue = mean(G1Data) - mean(G2Data);
    abscritvalue = abs(critvalue);

    pValues(1) = sum(StatDist>=critvalue, 2);
    pValues(2) = sum(StatDist<=critvalue, 2);
    pValues(3) = sum(absStatDist>=abscritvalue, 2);

    pValues = pValues / permutations;
end
