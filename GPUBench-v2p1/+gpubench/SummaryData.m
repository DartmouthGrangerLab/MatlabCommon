classdef SummaryData
    %SUMMARYDATA  a class to store GPUBench summary data
    %
    %   s = gpubench.SummaryData(data) creates a summary data object from
    %   some previously stored GPUBench data.
    %
    %   See also: gpuBench
    
    %   Copyright 2011-2018 The MathWorks, Inc.
    
    %% Private properties
    properties (SetAccess=private)
        DeviceName        % List of names for each device
        FunctionName      % List of names for each function
        Datatype          % List of datatype used
        LongName          % The long form of the function name to use in legends etc
        IsSelectedDevice  % True for the selected device, false for the others
        IsGPU             % True for GPU devices, false for CPU
        PeakFLOPS         % Array of peak results for each function run on each device
        Score             % Relative ranking for each device
        SortOrder         % The order of the summary data with respect to the original
    end
    
    %% Public methods
    methods
        function obj = SummaryData( data )
            % Construct a new summary data object
            
            N = numel( data );
            
            % First get the full list of function names across all results
            obj.DeviceName = cell(N,1);
            obj.IsSelectedDevice = [data.IsSelected];
            obj.IsGPU = ~[data.IsHostData];
            functionNames = cell(N,1);
            datatypes = cell(N,1);
            longNames = cell(N,1);
            peakFlops = cell(N,1);
            for jj=1:numel(data)
                thisResults = data(jj).Results;
                M = numel( thisResults );
                obj.DeviceName{jj} = data(jj).getDeviceName();
                functionNames{jj} = cell( 1, M );
                datatypes{jj} = cell( 1, M );
                longNames{jj} = cell( 1, M );
                peakFlops{jj} = zeros( 1, M );
                for ii=1:M
                    datatypes{jj}{ii} = thisResults(ii).DataType;
                    functionNames{jj}{ii} = thisResults(ii).FunctionName;
                    datatypes{jj}{ii} = thisResults(ii).DataType;
                    longNames{jj}{ii} = [functionNames{jj}{ii},' (',datatypes{jj}{ii},')'];
                    % Times that are too fast to accurately measure come
                    % back as zeros. Only include finite flop counts!
                    flops = thisResults(ii).NumOps ./ thisResults(ii).Times;
                    peakFlops{jj}(ii) = max(flops(isfinite(flops)));
                end
            end
            datatypes = [datatypes{:}];
            functionNames = [functionNames{:}];
            
            % Work out the Union of the names and pad any missing ones with zero
            % results
            [obj.LongName,idx] = unique( [longNames{:}] );
            obj.Datatype = datatypes(idx);
            obj.FunctionName = functionNames(idx);
            
            % Now create the table of results
            M = numel( obj.LongName );
            obj.PeakFLOPS = nan( N, M );
            for row=1:N
                [~,col] = ismember( longNames{row}, obj.LongName );
                obj.PeakFLOPS(row, col) = peakFlops{row};
            end
            
            % Calculate the score used for ordering the rows
            obj.Score = calculateScore(obj);
            
            % Sort the scores and re-jig the summary data accordingly
            obj = sortResults( obj );
            
        end % constructor
        
        function t = getDatatypes( obj )
            %getDataTypes  return a list of types used in the results
            %   Typically this is just 'single' and 'double'.
            t = unique( obj.Datatype );
        end % getDatatypes

        function cols = getColsForType( obj, typename )
            %getColsForType  return the indices of columns for the specified type
            %
            %   Example:
            %     >> getColsForType(results, 'double')
            %     ans = 1  3  5
            if iscell( typename )
                cols = cell( size( typename ) );
                for ii=1:numel(cols)
                    cols{ii} = obj.getColsForType( typename{ii} );
                end
            else
                cols = find( strcmp( obj.Datatype, typename ) );
            end
        end % getColsForType
    end
    
    %% Protected methods
    methods (Access=protected)
        function score = calculateScore(obj)
            % Create a score based on the performance in each category
            % relative to the best performance. Since MATLAB defaults to
            % using doubles we ignore singles in this score.
            normalizedFLOPS = bsxfun( @rdivide, obj.PeakFLOPS, max( obj.PeakFLOPS, [], 1 ) );
            normalizedFLOPS = normalizedFLOPS( :, strcmpi( obj.Datatype, 'double' ) );
            N = size( normalizedFLOPS, 1 );
            % NaN's indicate missing data, so we must ignore them
            score = zeros( N, 1 );
            for ii=1:N
                valid = ~isnan( normalizedFLOPS(ii,:) );
                score(ii) = mean( normalizedFLOPS(ii, valid) );
            end
        end % calculateScore
        
        function obj = sortResults(obj)
            % There are two different "sort"s we wish to apply. First we
            % want to order the devices according their "score". Next we
            % want to arrange the functions by data-type and then by peak
            % performance.
            
            % First put the devices into order
            [obj.Score,obj.SortOrder] = sort( obj.Score, 'descend' );
            obj.DeviceName = obj.DeviceName(obj.SortOrder);
            obj.PeakFLOPS = obj.PeakFLOPS(obj.SortOrder,:);
            obj.IsSelectedDevice = obj.IsSelectedDevice(obj.SortOrder);
            obj.IsGPU = obj.IsGPU(obj.SortOrder);
            
            % Now sort by the peak performance for each function
            [~,idx] = sort( max( obj.PeakFLOPS ), 'descend' );
            obj = reorderFunctions( obj, idx );
            
            % Sort by data-type, preserving the performance order within
            % each type.
            [~,idx] = sort( obj.Datatype );
            obj = reorderFunctions( obj, idx );
        end
        
        function obj = reorderFunctions( obj, idx )
            assert( numel(idx) == numel(obj.LongName) );
            obj.PeakFLOPS = obj.PeakFLOPS(:,idx);
            obj.FunctionName = obj.FunctionName(idx);
            obj.LongName = obj.LongName(idx);
            obj.Datatype = obj.Datatype(idx);
        end % reorderFunctions
        
    end % Protected methods
    
end

