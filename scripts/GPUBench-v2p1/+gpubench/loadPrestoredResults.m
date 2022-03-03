function results = loadPrestoredResults()
% Load all gpuBench pre-stored results.

% Copyright 2020-2021 The MathWorks, Inc.

folder = gpubench.getResultsDir();
results = gpubench.PerformanceData.empty(0,1);

files = dir(fullfile(folder , '*.gpubench.json'));
if isempty(files)
    warning('GPUBench:NoResults', 'No results files found in %s.', folder);
    return;
end

for ii=1:numel(files)
    thisFilename = fullfile(folder, files(ii).name);
    try
        r = gpubench.PerformanceData.readFromJSON(thisFilename);
        results(end+1,1) = r; %#ok<AGROW>
    catch err %#ok<NASGU>
        warning('GPUBench:BadResultsFile', 'Could not read results file %s.', files(ii).name);
    end
end

end % loadPrestoredResults