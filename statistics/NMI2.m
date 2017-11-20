%Program for calculating the Adjusted Mutual Information (AMI) between two clusterings, tested on Matlab 7.0 (R14)
%(C) Nguyen Xuan Vinh 2008-2010
%Contact: n.x.vinh@unsw.edu.au  vthesniper@yahoo.com
%--------------------------------------------------------------------------
%**Input: a contingency table T
%   OR
%        cluster label of the two clusterings in two vectors
%        eg: true_mem=[1 2 4 1 3 5]
%                 mem=[2 1 3 1 4 5]
%        Cluster labels are coded using positive integer. 
%RETURNS:
%   NMI - normalized mutual information
%   MI - mutual information
%--------------------------------------------------------------------------
%References: 
% [1] 'A Novel Approach for Automatic Number of Clusters Detection based on Consensus Clustering', N.X. Vinh, and Epps, J., in Procs. IEEE Int. Conf. on Bioinformatics and Bioengineering (Taipei, Taiwan), 2009.
% [2] 'Information Theoretic Measures for Clusterings Comparison: Is a Correction for Chance Necessary?', N.X. Vinh, Epps, J. and Bailey, J., in Procs. the 26th International Conference on Machine Learning (ICML'09)
% [3] 'Information Theoretic Measures for Clusterings Comparison: Variants, Properties, Normalization and Correction for Chance', N.X. Vinh, Epps, J. and Bailey, J., Journal of Machine Learning Research, 11(Oct), pages 2837-2854, 2010
% Copyright (c) 2011, Xuan Vinh Nguyen All rights reserved.
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%    * Redistributions of source code must retain the above copyright
%      notice, this list of conditions and the following disclaimer.
%    * Redistributions in binary form must reproduce the above copyright
%      notice, this list of conditions and the following disclaimer in
%      the documentation and/or other materials provided with the distribution
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
%Modified by Eli Bowen from AMI function to only calculate NMI, return 
function [nmi,MI] = NMI2 (true_mem, mem)
    if nargin == 1
        T = true_mem; %contingency table pre-supplied
    elseif nargin == 2
        %added by Eli Bowen 4/8/2017 for safety
        assert(sum(size(true_mem)>1)==1 && sum(size(mem)>1)==1 && numel(true_mem)==numel(mem), 'With 2 arguments, both arguments must be 1D and of equal length');
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

    n = sum(sum(T));
    
    %update the true dimensions
    [R,C] = size(T);
    if C>1 a=sum(T');else a=T';end;
    if R>1 b=sum(T);else b=T;end;

    %calculating the Entropies
    Ha = -(a/n)*log(a/n)'; 
    Hb = -(b/n)*log(b/n)';

    %calculate the MI (unadjusted)
    MI = 0;
    for i = 1:R
        for j = 1:C
            if T(i,j) > 0
                MI = MI + T(i,j)*log(T(i,j)*n/(a(i)*b(j)));
            end
        end
    end
    MI = MI / n;
    
    if MI == 0
        nmi = 0;
    else
        nmi = MI / sqrt(Ha*Hb);
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

            