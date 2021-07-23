function removeResults(datafile, gpuname)
%removeResults  remove some results from the stored data
%
%   GPUBENCH.REMOVERESULTS(DATAFILE, GPUNAME) tries to remove all records
%   for the GPU called GPUNAME from the stored data in DATAFILE.
%
%   Examples:
%   >> gpubench.removeResults('data/R2013a.mat', 'GeForce GTX TITAN');
%
%   See also: gpuBench, gpuBenchReport, gpubench.saveResults

%   Copyright 2013-2021 The MathWorks, Inc.

narginchk(2, 2);
if ~ischar(datafile)
    error( 'gpuBench:removeResults:InvalidFileName', ...
        'First argument must be the name of a gpuBench data-file.' );
end
if ~ischar(gpuname)
    error( 'gpuBench:removeResults:InvalidResultsName', ...
        'Second argument must be the name of the results to remove.' );
end

if ~exist(datafile, 'file')
    error( 'gpuBench:removeResults:NoSuchFile', ...
        'Could not open file ''%s'' for reading.', datafile );
end
data = load(datafile);
if ~isfield(data,'results') || ~isa(data.results, 'gpubench.PerformanceData')
    error( 'gpuBench:removeResults:BadResultsFile', ...
        'File does not appear to contain gpuBench results: ''%s''.', datafile );
end

results = data.results;
toRemove = arrayfun( @(x) matchesName(gpuname, x), results );
if any(toRemove)
    fprintf('Removing %d record(s) named ''%s'' from %s.\n', sum(toRemove), gpuname, datafile);
    results = results(~toRemove);
    save(datafile, 'results');
else
    fprintf('No records in %s match the name ''%s''.\n', datafile, gpuname);
end

end


function match = matchesName(name, result)
    % Helper to check whether some results have the specified name
    if result.IsHostData
        match = strcmpi('Host PC', name);
    else
        match = strcmpi(result.GPUInfo.Name, name);
    end
end