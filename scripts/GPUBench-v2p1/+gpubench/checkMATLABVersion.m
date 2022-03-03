function checkMATLABVersion()
%checkMATLABVersion  error if the MATLAB version is not suitable

%   Copyright 2011-2020 The MathWorks, Inc.

if verLessThan('matlab', '9.1.0')
    error('GPUBench:MATLABVersion', ...
        'GPUBench requires MATLAB version 9.1 (R2016b) or higher');
end
