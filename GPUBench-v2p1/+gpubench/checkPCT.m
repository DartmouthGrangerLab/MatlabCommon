function checkPCT()
%checkPCT  check that Parallel Computing Toolbox is installed and licensed

%   Copyright 2011-2018 The MathWorks, Inc.


pctInstalled = exist( 'gpuArray', 'file' ) == 2;
if ~pctInstalled
    error( 'GPUBench:PCTNotInstalled', 'GPUBench requires Parallel Computing Toolbox which does not appear to be installed.' );
end

pctLicensed = license( 'test', 'Distrib_Computing_Toolbox' );
if ~pctLicensed
    error( 'GPUBench:NoPCTLicense', 'No Parallel Computing Toolbox license was available.' );
end
