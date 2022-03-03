function gpuBenchLauncher()
% A wrapper around gpuBench for use in the app. This is required because
% the app launcher tries to capture an output argument, causing gpuBench to
% return the data instead of reporting it.
%
%   See also: gpuBench, gpuBenchReport

%   Author: Ben Tordoff
%   Copyright 2012-2014 The MathWorks, Inc.

gpuBench();