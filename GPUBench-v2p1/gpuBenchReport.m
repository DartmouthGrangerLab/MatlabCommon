function out = gpuBenchReport( varargin )
%gpuBenchReport  create an HTML report based on some GPU performance data
%
%   gpuBenchReport(data) creates a new HTML report based on the supplied
%   PerformanceData and opens it in the system browser.
%
%   gpuBenchReport() creates an HTML report based only on the pre-stored
%   performance data.
%
%   filename = gpuBenchReport(...) returns the location of the main page
%   for the report instead of viewing it immediately.
%
%   Examples:
%   >> gpuBenchReport
%   >> data = gpuBench;
%   >> gpuBenchReport( data )
%
%   See also: gpuBench

%   Copyright 2011-2021 The MathWorks, Inc.

narginchk( 0, 2 );
nargoutchk( 0, 1 );

% Try to get some comparison data
if nargin>0
    assert( all( cellfun( 'isclass', varargin, 'gpubench.PerformanceData' ) ) );
    [allData,allDataSummary] = getComparisonData( [varargin{:}]' );
else
    [allData,allDataSummary] = getComparisonData();
end
if isempty(allData)
    error( 'gpuBenchReport:NoData', 'No data to report' );
end

N = numel( allData );
gpubench.multiWaitbar( 'Creating GPUBench report...', 0, ...
    'Color', gpubench.progressColor() );

% Ensure the output folder exists
reportDir = fullfile( tempdir(), 'GPUBenchReport' );
if ~exist( reportDir, 'dir' )
    mkdir( reportDir );
end
copyFiles( reportDir );

% Store a copy of the user GPU data (if supplied)
userDataFiles = cell(nargin,1);
for ii=1:nargin
    thisData = varargin{ii};
    if ~thisData.IsHostData
        userDataFiles{ii} = thisData.getDefaultJSONFilename();
        thisData.writeAsJSON(fullfile(reportDir, userDataFiles{ii}));
    end
end
% Delete empty cells (CPU data)
userDataFiles(cellfun(@isempty, userDataFiles)) = [];

% Create the summary page for this device
makeSummaryBarChart( reportDir, allDataSummary );
reportname = makeSummaryPage( reportDir, allDataSummary, userDataFiles );
gpubench.multiWaitbar( 'Creating GPUBench report...', 'Increment', 1/(N+1) );

% Now create the detail pages for all devices
for ii=1:N
    makePerformancePlots( reportDir, allData, ii );
    makeDetailPage( reportDir, allData, allDataSummary, ii );
    gpubench.multiWaitbar( 'Creating GPUBench report...', 'Increment', 1/(N+1) );
end

gpubench.multiWaitbar( 'Creating GPUBench report...', 'close' );

if nargout
    out = reportname;
else
    web( reportname );
end

end % gpuBenchReport

%-------------------------------------------------------------------------%
function [allData,allDataSummary] = getComparisonData(data)

if nargin<1 || isempty(data)
    data = [];
    % No user data, so use the current release
    thisRelease = regexp( version, 'R\d*[ab]', 'match' );
    thisRelease = thisRelease{1};
else
    % Work out which data-file to use from the release
    thisRelease = data(1).MATLABRelease;
    % Flag the user's data so that we can highlight it
    for ii=1:numel(data)
        data(ii).IsSelected = true;
    end
end

% Try to load the data for this release
otherData = loadOtherData(data);

if isempty(otherData)
    error( 'GPUBenchReport:NoData', ...
        ['No pre-stored data was found. Please re-download and install ', ...
        'gpuBench from the <a href="https://www.mathworks.com/matlabcentral/fileexchange/34080">File Exchange</a>.'] );
end

% Filter out data for devices which are not supported by this release.
[minCC, maxCC] = gpubench.getSupportedComputeCapabilityForRelease(thisRelease);
otherDataComputeCapabilities = arrayfun(@iGetComputeCapability, otherData);
isSupportedByThisRelease = otherDataComputeCapabilities >= minCC & otherDataComputeCapabilities <= maxCC;
otherData = otherData(isSupportedByThisRelease);

% Construct the summary statistics from all the results and then sort the
% original data using the summary score.
if nargin>0
    allData = [data;otherData];
else
    allData = otherData;
end

if isempty( allData )
    % No data at all, we can't continue
    error( 'GPUBenchReport:NoData', ...
        ['Could not find pre-stored data (%s). ' ...
        'Check the File Exchange for an updated version or use gpuBench ', ...
        'to view the results for your system.'], gpubench.getDataDir() );
end

allDataSummary = gpubench.SummaryData( allData );
allData = allData(allDataSummary.SortOrder);
end % getComparisonData

%-------------------------------------------------------------------------%
function otherData = loadOtherData(existingData)

otherData = gpubench.loadPrestoredResults();

% We don't want to see a result for the exact same card
if ~isempty(existingData)
    % If the existing data contains some host data, don't keep any from the
    % loaded data
    if any([existingData.IsHostData])
        otherData([otherData.IsHostData]) = [];
    end
    % Extract the names in the new data
    existingNames = arrayfun(@getDeviceName, existingData, 'UniformOutput', false);
    % Extract the names for comparison
    otherNames = arrayfun(@getDeviceName, otherData, 'UniformOutput', false);
    % Keep only those in otherData that aren't in existingData
    [~,idx] = setdiff(otherNames, existingNames);
    otherData = otherData(idx);
end
end % loadOtherData

function cc = iGetComputeCapability(data)
% Extract compute capability of the GPU used for some results. NaN for CPU
% results.
assert(isscalar(data), 'iGetComputeCapability expects one set of results data at a time');
if data.IsHostData
    cc = NaN;
else
    cc = str2double(data.GPUInfo.ComputeCapability);
end
end

%-------------------------------------------------------------------------%
function makeSummaryBarChart( outDir, summaryData )

assert( isa( summaryData, 'gpubench.SummaryData' ) );

N = numel( summaryData.DeviceName );
deviceNames = summaryData.DeviceName;
functionNames = summaryData.LongName;
flopsResults = summaryData.PeakFLOPS;
isSelected = summaryData.IsSelectedDevice;
isGPU = summaryData.IsGPU;

% Sort by data-type
types = unique( summaryData.Datatype );
numOfType = zeros(size(types));
colsForType = cell(size(types));
for ii=1:numel(types)
    match = strcmp( summaryData.Datatype, types{ii} );
    numOfType(ii) = sum( match );
    colsForType{ii} = find( match );
end
colOrder = [colsForType{:}];
functionNames = functionNames(colOrder);
flopsResults = flopsResults(:,colOrder);


figh = gpubench.makeFigure( 'Summary' );
set(figh,'Position',[10 10 650 650])
bars = barh( flopsResults'/1e9 );
set( gca, 'YTickLabel', functionNames, 'YDir', 'Reverse' )
xlabel( sprintf('GFLOPS\n(higher is better)') )

% Highlight the selected entries
for ii=find(isSelected)
    if isGPU(ii)
        deviceNames{ii} = ['{\bfYour GPU (',deviceNames{ii},')}'];
    else
        deviceNames{ii} = '{\bfYour CPU}';
    end
end

gpubench.legend( deviceNames{:}, 'Location', 'NorthEast' );
grid on
title( 'Performance Summary' )

% Set colors to fade from blue to red
colors = parula(N);
for ii=1:N
    set( bars(ii), 'FaceColor', colors(ii,:), 'EdgeColor', 0.5*colors(ii,:) );
end

% highlight the user's result
%highlightColor = [1 0 0];
selectedResults = find(summaryData.IsSelectedDevice);
N = numel(selectedResults);
for ii=1:N
    existingColor = colors(selectedResults(ii), :);
    newColor = 1 - 0.35*(1 - existingColor);
    %newColor = highlightColor * (N-ii+2)/(N+1);
    set( bars(selectedResults(ii)), ...
        'FaceColor', newColor, ...
        'EdgeColor', [0 0 0], ...
        'Linewidth', 1.5 );
end

% Add dividers between types
hold on
x = get(gca,'XLim');
for ii=1:numel(numOfType)-1
    plot( x, (numOfType(ii)+0.5)*[1 1], 'k-', 'HandleVisibility', 'off');
end
gpubench.addGradientToAxes( gca() );
set( gca(), 'YGrid', 'off' );


% Save the image to file for the HTML to pick up
filename = 'summarychart.png';
gpubench.captureFigure( figh, fullfile( outDir, filename ), false );
close( figh );
end % makeSummaryBarChart

%-------------------------------------------------------------------------%
function makePerformancePlots( outDir, data, thisIdx )
%Create a FLOPS plot for each results in data with the "thisIdx" result
%highlighted.

fileBase = sprintf('device%d',thisIdx);

plotNames = arrayfun( @(x) x.getDeviceName(), data, 'UniformOutput', false );
plotNames{thisIdx} = ['{\bf',plotNames{thisIdx}, ' (selected)}'];

results = data(thisIdx).Results;

linestyle = {'-', '--', ':'};
numLinestyles = numel(linestyle);

for rr=1:numel( results )
    name = [results(rr).FunctionName, ' (', results(rr).DataType, ')'];
    figh = gpubench.makeFigure( name );
    color = get( gca(), 'ColorOrder' );
    numColors = size(color,1);
    
    % Plot each device's curve, if they have the relevant data
    for ii=1:numel(data)
        colorIdx = mod(ii-1,numColors)+1;
        linestyleIdx = mod(floor((ii-1)/numColors), numLinestyles)+1;
        % Find the corresponding result
        if hasResult( data(ii), name )
            linewidth = 1+2*(ii==thisIdx);
            gpubench.plotFLOPS( getResult( data(ii), name ), ...
                color(colorIdx,:), linestyle{linestyleIdx}, linewidth )
        else
            % We still need to plot something for the legend to be correct
            plot( nan, nan, 'Color', color(colorIdx,:), ...
                'Linestyle', linestyle{linestyleIdx}, 'LineWidth', 1 );
        end
    end
    % Add a highlight around the peak-flops point
    colorIdx = mod(thisIdx-1,size(color,1))+1;
    thisResult = getResult( data(thisIdx), name );
    [maxVal,maxIdx] = max( 1e-9 * thisResult.NumOps ./ thisResult.Times);
    plot( thisResult.Sizes(maxIdx), maxVal, ...
        'Color', color(colorIdx,:), ...
        'Marker', 'o', ...
        'MarkerSize', 16, ...
        'Linewidth', 2 );
    
    title( name );
    gpubench.legend( plotNames{:}, 'Location', 'NorthWest' );
    gpubench.addGradientToAxes( gca() );
    
    outerpos = get( gca, 'OuterPosition' );
    ti = get( gca, 'TightInset' );
    left = outerpos(1) + ti(1);
    bottom = outerpos(2) + ti(2);
    ax_width = outerpos(3) - ti(1) - ti(3);
    ax_height = outerpos(4) - ti(2) - ti(4);
    set( gca, 'Position', [left bottom ax_width ax_height] );
    
    % Save the image to file for the HTML to pick up
    filename = [fileBase,'-',results(rr).FunctionName,'-',results(rr).DataType,'.png'];
    gpubench.captureFigure( figh, fullfile( outDir, filename ) );
    close( figh );
end
end % makePerformancePlots

%-------------------------------------------------------------------------%
function copyFiles( outDir )
% Copy the required stylesheet and other files into the report folder

dataDir = gpubench.getDataDir();

files = {
    'gpubench.css'
    'background.png'
    'tableSort.js'
    };
for ii=1:numel(files)
    copyfile( fullfile( dataDir, files{ii} ), outDir, 'f' );
end
end % copyFiles

%-------------------------------------------------------------------------%
function reportname = makeSummaryPage( outDir, summaryData, userDataFiles )
% Create the summary page for this device

assert( isa( summaryData, 'gpubench.SummaryData' ) );

% Find the user's data
userIdx = find( summaryData.IsSelectedDevice, 1, 'first' );
if isempty( userIdx )
    % No user data, so use the first one
    pageName = '';
else
    pageName = [': ', summaryData.DeviceName{userIdx}];
end
reportname = fullfile( outDir, 'index.html' );

fid = fopen( reportname, 'wt' );
fprintf( fid, '<html><head>\n' );
fprintf( fid, '  <title>GPU Comparison Report%s</title>\n', pageName );
fprintf( fid, '  <link rel="stylesheet" type="text/css" href="gpubench.css"/>\n' );
fprintf( fid, '  <meta author="Generated by GPUBench."/>\n' );
fprintf( fid, '</head>\n' );
fprintf( fid, '<body>\n' );

% All of the content goes in a giant table to control the width
fprintf( fid, '  <center><table class="mainlayout"><tr><td>\n' );
fprintf( fid, '  <h1>GPU Bench</h1>\n' );

% Main title
fprintf( fid, '  <h2>GPU Comparison Report%s</h2>\n', pageName );

% Summary section
fprintf( fid, '  <h3>Summary of results</h3>\n' );

% Add the description
writeBoilerPlate( fid, 'summary_intro.html' )

% Add links to user files (if any)
if ~isempty(userDataFiles)
    fprintf(fid, '  <small><b>Shareable data files: ');
    for ii=1:numel(userDataFiles)
        fprintf(fid, '<a href="%s" download="%s">%s</a>', ...
            userDataFiles{ii}, userDataFiles{ii}, fullfile(outDir, userDataFiles{ii}));
        if ii<numel(userDataFiles)
            fprintf(fid, ', ');
        end
    end
    fprintf(fid, '</b></small><br/><br/>\n\n' );
end

names = summaryData.FunctionName;
numCols = numel( names );

% Print the table header
fprintf( fid, '  <table border="0" width="100%%"><tr><td align="center">\n' );
fprintf( fid, '  <table id="sortable" class="summarytable" cellspacing="0">\n' );

% Titles for types
types = getDatatypes( summaryData );
colsForType = getColsForType( summaryData, types );
numOfType = cellfun( 'length', colsForType );
%types = repelem(types, numOfType);
colOrder = [colsForType{:}];
fprintf( fid, '    <thead>\n' );
fprintf( fid, '      <tr class="summarytable">\n' );
fprintf( fid, '        <th data-type="nosort" class="summarytable"></th>\n' );
for ii=1:numel(types)
    fprintf( fid, '        <th data-type="nosort" class="summarytable" colspan="%d">%s precision results (in GFLOPS)</th>\n', numOfType(ii), strcat(upper(types{ii}(1)), types{ii}(2:end)) );
end
fprintf( fid, '      </tr>\n' );
fprintf( fid, '      <tr class="summarytable">\n' );
fprintf( fid, '        <th data-type="nosort" class="summarytable"></th>\n' );
for cc=1:numCols
    fprintf( fid, '        <th data-type="number" class="summarytable" style="cursor:pointer">%s</th>\n', names{colOrder(cc)} );
end
fprintf( fid, '      </tr>\n' );
fprintf( fid, '    </thead>\n' );
% Now the body
fprintf( fid, '    <tbody>\n' );
for rr=1:numel(summaryData.DeviceName)
    fprintf( fid, '      <tr class="summarytable">\n' );
    if (summaryData.IsSelectedDevice(rr))
        if summaryData.IsGPU(rr)
            nameStr = ['<b>Your GPU</b> (',summaryData.DeviceName{rr},')'];
        else
            nameStr = '<b>Your CPU</b>';
        end
        cellformat = '        <td class="summarytable" align="right"><a href="device%d.html#result%u"><b>%1.2f</b></a></td>\n';
    else
        nameStr = summaryData.DeviceName{rr};
        cellformat = '        <td class="summarytable" align="right"><a href="device%d.html#result%u">%1.2f</a></td>\n';
    end
    fprintf( fid, '        <td class="summarytable" align="left"><a href="device%d.html">%s</a></td>\n', rr, nameStr );
    for cc=1:numCols
        colIdx = colOrder(cc);
        fprintf( fid, cellformat, rr, colIdx, summaryData.PeakFLOPS(rr,colIdx) / 1e9 );
    end
    fprintf( fid, '      </tr>\n' );
end
fprintf( fid, '    </tbody>\n' );
fprintf( fid, '  </table>\n\n' );
fprintf( fid, '  <script src="tableSort.js"></script>\n' );
fprintf( fid, '  <small><br/><b>(Sort the results by clicking on any column title. To see detailed performance data, click on an individual result or a device name.)</b></small><br/>\n\n' );

% Add the summary image
fprintf( fid, '  <img src="summarychart.png"/>\n\n' );
fprintf( fid, '  </td></tr></table>\n' );

% Footer
fprintf( fid, '  <hr/>\n' );
writeGeneratedBy( fid );

% Close the main layout table
fprintf( fid, '  </td></tr></table></center>\n' );
fprintf( fid, '</body>\n' );
fprintf( fid, '</html>\n' );
fclose( fid );
end % makeSummaryPage

%-------------------------------------------------------------------------%
function makeDetailPage( outDir, data, summaryData, thisIdx )
% Create page of detailed information for one device
name = summaryData.DeviceName{thisIdx};
fileBase = sprintf('device%d',thisIdx);

reportname = fullfile( outDir, [fileBase,'.html'] );

fid = fopen( reportname, 'wt' );
fprintf( fid, '<html><head>\n' );
fprintf( fid, '  <title>GPU Performance Details: %s</title>\n', name );
fprintf( fid, '  <link rel="stylesheet" type="text/css" href="gpubench.css"/>\n' );
fprintf( fid, '  <meta author="Generated by GPUBench."/>\n' );
fprintf( fid, '</head>\n' );
fprintf( fid, '<body>\n' );

% All of the content goes in a giant table to control the width
fprintf( fid, '  <center><table class="mainlayout"><tr><td>\n' );
fprintf( fid, '  <a class="noUnderline" href="index.html"><h1>GPU Bench</h1></a>\n' );

% Main title
fprintf( fid, '  <h2>GPU Performance Details: %s</h2>\n', name );

% Contents section
fprintf( fid, '  <table class="contents"><tr><td valign="top">\n' );
fprintf( fid, '    <b>Contents:</b>\n' );
fprintf( fid, '  </td><td valign="top">\n' );
names = summaryData.LongName;
fprintf( fid, '    <ul>\n' );
fprintf( fid, '      <li><a href="#config">System Configuration</a></li>\n' );

% Sort the contents by type
types = getDatatypes( summaryData );

for tt=1:numel( types )
    fprintf( fid, '      <li>Results for datatype %s</a><ul>\n', types{tt} );
    colsForType = getColsForType( summaryData, types{tt} );
    for nn=1:numel( colsForType )
        myCol = colsForType(nn);
        fprintf( fid, '        <li><a href="#result%u">%s</a></li>\n', myCol, names{myCol} );
    end
    fprintf( fid, '      </ul></li>\n' );
end
fprintf( fid, '    </ul>\n' );
fprintf( fid, '  </tr></table>\n' );
fprintf( fid, '  <br/>\n' );


% Add a section showing the operating environment
fprintf( fid, '  <a class="noUnderline" name="config"><h3>System Configuration</h3></a>\n' );
fprintf( fid, '  <p><b>MATLAB Release:</b> %s</p>\n', data(thisIdx).MATLABRelease );
fprintf( fid, '  <table>\n' );
fprintf( fid, '    <tr>\n' );
fprintf( fid, '      <td valign="top" align="center" style="padding:0 15px 0 0;">\n' );
fprintf( fid, '        <p><b>Host</b></p>\n' );
writeStructTable( fid, data(thisIdx).CPUInfo );
% - only add the GPU if we ran on it
if ~data(thisIdx).IsHostData
    fprintf( fid, '      </td>\n' );
    fprintf( fid, '      <td valign="top" align="center">\n' );
    fprintf( fid, '        <p><b>GPU</b></p>\n' );
    writeStructTable( fid, data(thisIdx).GPUInfo );
end
fprintf( fid, '      </td>\n' );
fprintf( fid, '    </tr>\n' );
fprintf( fid, '  </table>\n' );
fprintf( fid, '  <br/>\n' );

% Add one section per result
names = summaryData.LongName;
for nn=1:numel( names )
    fprintf( fid, '  <a class="noUnderline" name="result%u"><h3>Results for %s</h3></a>\n', nn, names{nn} );
    if ~hasResult( data(thisIdx), names{nn} )
        % No results for this function
        fprintf( fid, '  <p>No results found for %s.</p>\n', names{nn} );
        continue;
    end
    myResult = getResult( data(thisIdx), names{nn} );
    % See if there's a description for this function
    writeBoilerPlate( fid, [myResult.FunctionName,'.html'] )
    
    fprintf( fid, '  <table cellspacing="0" width="1000px">\n');
    fprintf( fid, '    <tr>\n' );
    fprintf( fid, '      <td valign="top" align="left">\n' );
    fprintf( fid, '        <table>\n');
    fprintf( fid, '          <tr>\n');
    fprintf( fid, '            <td>\n');
    fprintf( fid, '              <b>Raw data for %s - %s</b>\n', name, names{nn} );
    fprintf( fid, '            </td>\n');
    fprintf( fid, '          </tr>\n');
    fprintf( fid, '          <tr>\n');
    fprintf( fid, '            <td>\n');
    
    % Print the table header
    fprintf( fid, '              <table class="summarytable" cellspacing="0">\n' );
    fprintf( fid, '                <tr>\n' );
    fprintf( fid, '                  <th class="summarytable">Array size<br/>(elements)</th>\n' );
    fprintf( fid, '                  <th class="summarytable">Num<br/>Operations</th>\n' );
    fprintf( fid, '                  <th class="summarytable">Time<br/>(ms)</th>\n' );
    fprintf( fid, '                  <th class="summarytable">GigaFLOPS</th>\n' );
    fprintf( fid, '                </tr>\n' );
    % Now one row per size
    sizes = myResult.Sizes;
    flops = myResult.NumOps;
    times = myResult.Times;
    [~,peakIdx] = max( flops ./ times );
    baseFormatStr1 = '                  <td class="summarytable" align="right">';
    baseFormatStr2 = '</td>\n';
    for ss=1:numel(sizes)
        % Highlight the peak FLOPS row
        if ss==peakIdx
            formatStr1 = [baseFormatStr1,'<font color="#0000dd">'];
            formatStr2 = ['</font>',baseFormatStr2];
        else
            formatStr1 = baseFormatStr1;
            formatStr2 = baseFormatStr2;
        end
        fprintf( fid, '                <tr>\n' );
        fprintf( fid, [formatStr1,'%s',formatStr2], num2strWithCommas(sizes(ss)) );
        fprintf( fid, [formatStr1,'%s',formatStr2], num2strWithCommas(flops(ss)) );
        fprintf( fid, [formatStr1,'%2.2f',formatStr2], times(ss)*1000 );
        fprintf( fid, [formatStr1,'%2.2f',formatStr2], flops(ss)/times(ss)/1e9 );
        fprintf( fid, '                </tr>\n' );
    end
    fprintf( fid, '              </table>\n' );
    fprintf( fid, '              <center><small>(<code>N</code> gigaflops = <code>Nx10<sup>9</sup></code> operations per second)</small></center><br/>\n' );
    fprintf( fid, '            </td>\n');
    fprintf( fid, '          </tr>\n');
    fprintf( fid, '        </table>\n');
    fprintf( fid, '      </td>\n');
    
    % Add the image
    fprintf( fid, '      <td valign="top" align="right">\n' );
    fprintf( fid, '        <img src="%s-%s-%s.png" width = "650px">\n', ...
        fileBase, myResult.FunctionName, myResult.DataType );
    fprintf( fid, '      </td>\n');
    fprintf( fid, '    </tr>\n');
    fprintf( fid, '  </table>\n');
end

% Footer
fprintf( fid, '  <hr/>\n' );

fprintf( fid, '  <table width="100%%"><tr><td align="left">\n' );
writeGeneratedBy( fid );
fprintf( fid, '  </td><td align="right">\n' );
fprintf( fid, '    <small><a href="index.html"><i>Back to summary</i></a></small>\n' );
fprintf( fid, '  </td></tr></table>\n' );

% Close the main layout table
fprintf( fid, '  </td></tr></table></center>\n' );
fprintf( fid, '</body>\n' );
fprintf( fid, '</html>\n' );
fclose( fid );
end % makeDetailPage

%-------------------------------------------------------------------------%
function writeStructTable( fid, data )
assert( isstruct( data ) && isscalar( data ) );
fprintf( fid, '        <table class="summarytable" cellspacing="0">\n' );
fields = fieldnames( data );
for ff=1:numel( fields )
    fprintf( fid, '          <tr><th class="summarytable" align="left">%s</th>', fields{ff} );
    fprintf( fid, '<td class="summarytable" valign="middle">' );
    x = data.(fields{ff});
    if ischar( x )
        fprintf( fid, '%s', x );
    elseif isinteger( x )
        fprintf( fid, '%d', x );
    else
        % Try to let MATLAB do the right thing
        fprintf( fid, '%g', x );
    end
    fprintf( fid, '</td></tr>\n' );
end
fprintf( fid, '        </table>\n' );
end % writeStructTable

%-------------------------------------------------------------------------%
function writeBoilerPlate( outFid, filename )
%Read some boiler-plate HTML and paste it into the supplied output file
filename = fullfile( gpubench.getDataDir(), filename );
inFid = fopen( filename, 'rt' );
if inFid<=0
    warning( 'gpuBenchReport:MissingBoilerPlateFile', ...
        'Input file could not be opened: %s', filename );
    return;
end
txt = fread( inFid );
fwrite( outFid, txt );
fclose( inFid );
end % writeBoilerPlate

%-------------------------------------------------------------------------%
function writeGeneratedBy( outFid )
%Write the "generated by" string into the footer

fprintf( outFid, '  <small><i>Generated by gpuBench v%s: %s</i></small>\n', ...
    gpubench.version(), datestr( now(), 'yyyy-mm-dd HH:MM:SS' ) );
end % writeGeneratedBy

%-------------------------------------------------------------------------%
function str = num2strWithCommas( num )
%Convert an integer into a string with commas separating sets of 3 digits
%
%  e.g. num2StrWithCommas(12345678) = '12,345,678'

% First convert using the standard method
baseStr = num2str( abs(num) );
% now insert some commas.
% pad to a multiple of 3
padding = 3 - (mod(length(baseStr)-1,3)+1);
str = [repmat(' ',1,padding), baseStr];
numCols = length(str)/3;
str = [reshape(str,3,numCols);repmat(',',1,numCols)];
str = strtrim( str(1:end-1) );
% Finally, re-insert the sign
if num<0
    str = ['-',str];
end
end % num2StrWithCommas
