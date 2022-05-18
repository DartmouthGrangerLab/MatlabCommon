% deprecated
function [pValues] = fppermutationtestmp (G1Data, G2Data, simulate, permutations)
    validateattributes(G1Data, {'numeric'}, {'vector'}, 1);
    validateattributes(G2Data, {'numeric'}, {'vector'}, 2);
    validateattributes(simulate, {'logical','numeric'}, {'scalar'}, 3);
    assert(all(size(G1Data)==size(G2Data)), 'Data vectors must be the same size');
    G1Data = G1Data(:); %ensure column vector
    G2Data = G2Data(:); %ensure column vector

    %Revert to default number of permutations if unspecified
    if nargin == 3
        permutations = 50000;
    end

    %Initialise variables
    N = numel(G1Data); %number of pairs
    DifferenceVector = G1Data - G2Data;

    if simulate == 1
        SignMatrix = 1 - 2*round(rand(permutations, N));
    else
        permutations = 2^N;

        if permutations > 1000000
            check = input(['Running with ',num2str(permutations) ,' permutations. Continue? [Y/N]: '],'s');
            if check =='N'
                pValues = [];
                return
            end
        end

        D = (0:permutations-1)';
        SignMatrix = 1 - 2*rem(floor(D*pow2(-(N-1):0)),2);  
    end
    
    StatDist = SignMatrix * DifferenceVector; %compute the statistic for all the permutations
    
    critvalue = sum(DifferenceVector); %critical value for given allocation

    pValues(1) = sum(StatDist>=critvalue, 1);
    pValues(2) = sum(StatDist<=critvalue, 1);
    pValues(3) = 2 * min(pValues);

    pValues = pValues / permutations;
end