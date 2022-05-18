% nomalized mutual information
% Written by Mo Chen (mochen@ie.cuhk.edu.hk). March 2009.
% http://www.mathworks.com/matlabcentral/fileexchange/29047-normalized-mutual-information/content//nmi.m
% http://nlp.stanford.edu/IR-book/html/htmledition/evaluation-of-clustering-1.html
%NOTE: I think NMI2 is more correct - it often returns the same value, but sometimes not. (Eli Bowen 5/2017)
% INPUTS
%   label - a 1D vector
%   result - a 1D vector
% RETURNS
%   v - should be between 0 and 1
% see also NMI2
function v = NMI(label, result)
    assert(length(label) == length(result));

    label = label(:);
    result = result(:);

    n = length(label);

    label_unique = unique(label);
    result_unique = unique(result);

    %check the integrity of result
    if length(label_unique) ~= length(result_unique)
        v = -1;
        return
    end

    c = length(label_unique);

    % distribution of result and label
    Ml = double(repmat(label,1,c) == repmat(label_unique',n,1));
    Mr = double(repmat(result,1,c) == repmat(result_unique',n,1));
    Pl = sum(Ml)/n;
    Pr = sum(Mr)/n;

    % entropy of Pr and Pl
    Hl = -sum(Pl .* log2(Pl + eps));
    Hr = -sum(Pr .* log2(Pr + eps));

    % joint entropy of Pr and Pl
    % M = zeros(c);
    % for I = 1:c
    % 	for J = 1:c
    % 		M(I,J) = sum(result==result_unique(I)&label==label_unique(J));
    % 	end;
    % end;
    % M = M / n;
    M = Ml'*Mr/n;
    Hlr = -sum(M(:) .* log2(M(:) + eps));

    % mutual information
    MI = Hl + Hr - Hlr;

    % normalized mutual information
    v = sqrt((MI/Hl)*(MI/Hr));
end
