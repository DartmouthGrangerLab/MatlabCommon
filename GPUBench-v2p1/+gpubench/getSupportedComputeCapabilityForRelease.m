function [minCC, maxCC] = getSupportedComputeCapabilityForRelease(release)
%getSupportedComputeCapabilityForRelease  get the minimum and mximum
%compute capability that was natively supported for a given MATLAB release.

%   Copyright 2020 The MathWorks, Inc.

switch release
    case {'R2021a'}
        minCC = 3.5;
        maxCC = 8.0;
    case {'R2020b', 'R2020a', 'R2019b', 'R2019a', 'R2018b', 'R2018a'}
        minCC = 3.0;
        maxCC = 7.5;
    case {'R2017b', 'R2017a'}
        minCC = 2.0;
        maxCC = 6.2;
    case {'R2016b', 'R2016a', 'R2015b', 'R2015a', 'R2014b'}
        minCC = 2.0;
        maxCC = 5.3;
    case {'R2014a', 'R2013b', 'R2013a', 'R2012b'}
        minCC = 1.3;
        maxCC = 3.7;
    case {'R2012a', 'R2011b', 'R2011a', 'R2010b'}
        minCC = 1.3;
        maxCC = 2.1;
    otherwise % Default values for future releases
        minCC = 3.5;
        maxCC = Inf;
end
end % getSupportedComputeCapabilityForRelease