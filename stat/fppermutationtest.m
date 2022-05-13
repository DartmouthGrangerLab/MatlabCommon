% Produces p-values from a Fisher-Pitman permutation test of independent samples
% INPUTS:
%   G1Data - A column vector of data from the first independent sample
%   G2Data - A column vector of data from the first independent sample
%   simulate - set to 1 to simulate the full permutation test
%   permutations - OPTIONAL - the number of permutations to run if simulation is chosen (default 50000)
% Copyright (c) 2017, Lachlan Johnstone All rights reserved.
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%Downloaded by Eli Bowen 6/11/2019 from: https://www.mathworks.com/matlabcentral/fileexchange/61155-fisher-pitman-permutation-tests
%modified only for readability and to improve input handling
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
