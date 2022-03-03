function saveResults( newData )
%saveResults  add some new results to the stored data
%
%   GPUBENCH.SAVERESULTS(NEWDATA) adds the supplied gpuBench result data to
%   the appropriate data-file.
%
%   Examples:
%   >> data = gpuBench;
%   >> gpubench.saveResults(data);
%
%   See also: gpuBench, gpuBenchReport

%   Copyright 2011-2020 The MathWorks, Inc.

if ~isa(newData, "gpubench.PerformanceData")
    error("gpuBenchSaveResults:BadData", ...
        "Input data must be a PerformanceData object as returned by gpuBench." );
end

% Work out the file name from the device name
fullname = fullfile( gpubench.getResultsDir(), newData.getDefaultJSONFilename() );

% Don't overwrite existing data
if exist(fullname, "file")
    error("gpuBenchSaveResults:FileExists", ...
        "Data for this device already exists. Existing data must be removed before storing new results." );
end

writeAsJSON(newData, fullname);

end
