function resultsDir = getResultsDir()
%getResultsDir  get the full path to the folder containing the GPUBench
% pre-stored results data

%   Copyright 2020-2021 The MathWorks, Inc.

baseFolder = fileparts(fileparts(mfilename('fullpath')));
resultsDir = fullfile(baseFolder, 'results');

