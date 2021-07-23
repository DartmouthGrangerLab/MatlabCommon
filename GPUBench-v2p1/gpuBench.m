function [outGPU,outHost] = gpuBench()
%GPUBENCH  MATLAB GPU Benchmark
%   GPUBENCH times different MATLAB GPU tasks and compares the execution
%   speed with the speed of several other GPUs.  The tasks are:
%
%    Backslash   Matrix left-division.    Floating point, regular memory access.
%    MTimes      Matrix multiplication.   Floating point, regular memory access.
%    FFT         Fast Fourier Transform.  Floating point, irregular memory access.
%
%   Each task is run for a range of array sizes and the results are tabulated
%   in an HTML report.  GPUBENCH can take several minutes to complete - please
%   be patient! Note that if your GPU is also driving your monitor then
%   the display may become unresponsive during testing.
%
%   GPUBENCH runs each of the tasks and shows a report indicating how the
%   current GPU compares to other systems.
%
%   T = GPUBENCH returns a data structure containing all of the results and
%   does not generate the report.
%
%   Fluctuations of up to ten percent in the measured times of repeated
%   runs on a single machine are not uncommon.  Your own mileage may vary.
%
%   This benchmark is intended to compare performance different GPUs on one
%   particular version of MATLAB.  It does not offer direct comparisons
%   between different versions of MATLAB.
%
%   See also: BENCH, gpuBenchReport

% Unused tasks:
%    Mandelbrot  Calculate a Mandelbrot Set.  Floating point, regular memory access.

%   Copyright 2011-2020 The MathWorks, Inc.

% Check for the right MATLAB version and availability of PCT
gpubench.checkMATLABVersion();
gpubench.checkPCT();

% Check for a GPU. We give the option of running without a GPU so that
% users can evaluate what benefits a GPU might give.
hasGPU = parallel.gpu.GPUDevice.isAvailable();
if ~hasGPU
    title = 'Continue without a GPU?';
    question = ['The GPU could not be used. ' ...
        'Do you wish to continue and collect results for your CPU?'];
    buttons = {'Collect CPU results', 'Stop'};
    answer = questdlg( question, title, buttons{:}, buttons{end} );
    if ~strcmp(answer,buttons{1})
        warning( 'GPUBench:NoGPU', 'No GPU was available for GPUBench to use.' );
        return;
    end
end

% Show the progress bar early as it is the first sign we are doing
% something!
% Do we need to measure the host stuff?
doHost = (nargout~=1);
numTasks = 6 * (hasGPU+doHost);
try
    progressTitle = 'Running GPUBench...';
    gpubench.multiWaitbar(progressTitle, 0, ...
        'Color', gpubench.progressColor(), ...
        'CancelFcn', @(a,b) disp('Aborting gpuBench...'));
    cleanup1 = onCleanup( @() gpubench.multiWaitbar(progressTitle, 'Close') );
    useProgressBar = true;
catch noJvmErr %#ok<NASGU>
    useProgressBar = false;
end
drawnow();

% Initialize the data object
release = regexp( version, 'R\d*[ab]', 'match' );
gpuData = gpubench.PerformanceData( ...
    release{1}, ...
    gpubench.cpuinfo(), ...
    gpubench.gpuinfo(), ...
    false, ... % isHostData
    now() );
hostData = gpubench.PerformanceData( ...
    release{1}, ...
    gpubench.cpuinfo(), ...
    struct(), ...
    true, ... % isHostData
    now() );

% Ignore HighOverhead warning when the array size is too small
highOverheadWarningId = 'parallel:gpu:gputimeit:HighOverhead';

% Add cleaner just in case of crashes
cleanup2 = onCleanup( @() warning( 'on', highOverheadWarningId ) );

warning( 'off', highOverheadWarningId );
if hasGPU
    gpuData = runBackslash( gpuData, 'single', 'GPU', useProgressBar, progressTitle, numTasks );
    gpuData = runBackslash( gpuData, 'double', 'GPU', useProgressBar, progressTitle, numTasks );

    gpuData = runMTimes( gpuData, 'single', 'GPU', useProgressBar, progressTitle, numTasks );
    gpuData = runMTimes( gpuData, 'double', 'GPU', useProgressBar, progressTitle, numTasks );

    gpuData = runFFT( gpuData, 'single', 'GPU', useProgressBar, progressTitle, numTasks );
    gpuData = runFFT( gpuData, 'double', 'GPU', useProgressBar, progressTitle, numTasks );
end

if doHost
    hostData = runBackslash( hostData, 'single', 'Host', useProgressBar, progressTitle, numTasks );
    hostData = runBackslash( hostData, 'double', 'Host', useProgressBar, progressTitle, numTasks );

    hostData = runMTimes( hostData, 'single', 'Host', useProgressBar, progressTitle, numTasks );
    hostData = runMTimes( hostData, 'double', 'Host', useProgressBar, progressTitle, numTasks );

    hostData = runFFT( hostData, 'single', 'Host', useProgressBar, progressTitle, numTasks );
    hostData = runFFT( hostData, 'double', 'Host', useProgressBar, progressTitle, numTasks );
end
warning( 'on', highOverheadWarningId )
abort = gpubench.multiWaitbar( progressTitle, 'Close' );

if abort
    % Return nothing
elseif nargout
    % User requested raw data
    outGPU = gpuData;
    outHost = hostData;
else
    % Produce report
    reportData = {};
    if hasGPU
        reportData{end+1} = gpuData;
    end
    if doHost
        reportData{end+1} = hostData;
    end
    web( gpuBenchReport( reportData{:} ) );
end


%-------------------------------------------------------------------------%
function data = runFFT( data, type, device, useProgressBar, mainProgressTitle, numTasks )
% Work out the maximum size we should run
safetyFactor = 10; % Based on trial and error. Requiring 10x the input seems safe.
sizes = getTestSizes( type, safetyFactor, device );
times = inf( size( sizes ) );
avgTime = 0;

if useProgressBar
    progressTitle = sprintf( 'FFT (%s, %s)', device, type );
    progressTotal = sum( sizes );
    gpubench.multiWaitbar( progressTitle, 0, 'Color', gpubench.progressColor()*0.8 );
    cleanup = onCleanup( @() gpubench.multiWaitbar( progressTitle, 'Close' ) );
end

for ii=1:numel(sizes)
    % Check for getting close to time-out
    if tooCloseToTimeout( avgTime, device )
        times(ii) = nan;
        continue;
    end

    N = sizes(ii);
    try
        A = complex( rand( N, 1, type ), rand( N, 1, type ) );
        if strcmpi( device, 'GPU' )
            A = gpuArray(A);
        end
        times(ii) = iTimeit( device, @()fft( A ) );
        avgTime = times(ii);

        if useProgressBar
            % Update both progress bars
            inc = sizes(ii)/progressTotal;
            gpubench.multiWaitbar( progressTitle, 'Increment', inc );
            abort = gpubench.multiWaitbar( mainProgressTitle, 'Increment', inc/numTasks );
            if abort
                return;
            end
        end

    catch err %#ok<NASGU>
    end
end

% Clear any dud results
sizes(isnan( times )) = [];
times(isnan( times )) = [];

data = addResult( data, 'FFT', type, sizes, 5*sizes.*log2(sizes), times );

%-------------------------------------------------------------------------%
function data = runMTimes( data, type, device, useProgressBar, mainProgressTitle, numTasks )
safetyFactor = 3.5; % Space for two inputs plus one output and a bit to spare
sizes = getTestSizes( type, safetyFactor, device );

times = inf( size( sizes ) );
avgTime = 0;

if useProgressBar
    progressTitle = sprintf( 'MTimes (%s, %s)', device, type );
    progressTotal = sum( sizes );
    gpubench.multiWaitbar( progressTitle, 0, 'Color', gpubench.progressColor()*0.8 );
    cleanup = onCleanup( @()gpubench.multiWaitbar( progressTitle, 'Close' ) );
end

N = round( sqrt( sizes ) );
for ii=1:numel(sizes)
    % Check for getting close to time-out
    if tooCloseToTimeout( avgTime, device )
        times(ii) = nan;
        continue;
    end
    try
        A = rand( N(ii), N(ii), type );
        B = rand( N(ii), N(ii), type );
        if strcmpi( device, 'GPU' )
            A = gpuArray(A);
            B = gpuArray(B);
        end

        times(ii) = iTimeit( device, @()A*B );
        avgTime = times(ii);

        if useProgressBar
            % Update both progress bars
            inc = sizes(ii)/progressTotal;
            gpubench.multiWaitbar( progressTitle, 'Increment', inc );
            abort = gpubench.multiWaitbar( mainProgressTitle, 'Increment', inc/numTasks );
            if abort
                return;
            end
        end
    catch err %#ok<NASGU>
    end
end

% Clear any dud results
N(isnan( times )) = [];
times(isnan( times )) = [];

data = addResult( data, 'MTimes', type, N.*N, N.*N.*(2.*N-1), times );

%-------------------------------------------------------------------------%
function data = runBackslash( data, type, device, useProgressBar, mainProgressTitle, numTasks )
safetyFactor = 1.5; % One full-sized matrix plus two vectors, so 1.5 is plenty
sizes = getTestSizes( type, safetyFactor, device );

% Limit the sizes to 1e8 for now to prevent problems
sizes(sizes>1e8) = [];
times = inf( size( sizes ) );
avgTime = 0;

if useProgressBar
    progressTitle = sprintf( 'Backslash (%s, %s)', device, type );
    progressTotal = sum(sizes);
    gpubench.multiWaitbar( progressTitle, 0, 'Color', gpubench.progressColor()*0.8 );
    cleanup = onCleanup( @()gpubench.multiWaitbar( progressTitle, 'Close' ) );
end

N = round( sqrt( sizes ) );
for ii=1:numel( sizes )
    % Check for getting close to time-out
    if tooCloseToTimeout( avgTime, device )
        times(ii) = nan;
        continue;
    end

    try
        A = 100*eye( N(ii), N(ii), type ) + rand( N(ii), N(ii), type );
        b = rand( N(ii), 1, type );
        if strcmpi( device, 'GPU' )
            A = gpuArray(A);
            b = gpuArray(b);
        end
        times(ii) = iTimeit( device, @()A\b );
        avgTime = times(ii);

        % Update both progress bars
        if useProgressBar
            inc = sizes(ii)/progressTotal;
            gpubench.multiWaitbar( progressTitle, 'Increment', inc );
            abort = gpubench.multiWaitbar( mainProgressTitle, 'Increment', inc/numTasks );
            if abort
                return;
            end
        end
    catch err %#ok<NASGU>
    end
end

% Clear any dud results
N(isnan( times )) = [];
times(isnan( times )) = [];

data = addResult( data, 'Backslash', type, N.*N, round( 2/3*N.^3 + 3/2*N.^2 ), times );

%-------------------------------------------------------------------------%
function sizes = getTestSizes( type, safetyFactor, device )
% Return the maximum number of elements that will fit in the device memory
elementSize = gpubench.sizeof( type );
% If no GPU to get memory size, so just go for 4GB
freeMem = 4*2^30;

if strcmpi( device, 'Host' )
    % On the host everything takes longer, so don't go as far
    safetyFactor = safetyFactor*2;
else
    % Use as much memory as we can.
    gpu = gpuDevice();
    freeMem = gpu.FreeMemory;
end

maxNumElements = floor( freeMem / (elementSize*safetyFactor) );
if isnan( maxNumElements ) || maxNumElements < 1e6
    error( 'gpuBench:NotEnoughMemory', 'Not enough free device memory to run tasks' );
end

% We want powers of two up to this size
maxPower = floor( log2( maxNumElements ) );
sizes = power( 2, 10:2:maxPower );

%-------------------------------------------------------------------------%
function stopNow = tooCloseToTimeout( time, device )
% Should a test stop early to avoid triggering the device time-out?
stopNow = false;
if strcmpi( device, 'Host' )
    % On the host there is no time limit
else
    gpu = gpuDevice();
    % If the kernel has a timeout it is typically 2-5 seconds. If we have
    % just done a size that takes (on average) more than a tenth of a second,
    % the next size will likely trigger the timeout.
    stopNow = (gpu.KernelExecutionTimeout && time>0.1);
end

%-------------------------------------------------------------------------%
function t = iTimeit( device, f )
% Depending by what device is selected, time f with gputimeit(gpu) or
% timeit(cpu)
if strcmp( device, 'GPU' )
    t = gputimeit( f );
else
    t = timeit( f );
end

