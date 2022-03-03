classdef PerformanceData
    %PERFORMANCEDATA  a class to store GPUBench performance data
    %
    %   p = gpuBench measures some performance data for your currently
    %   selected GPU. Do not use this class directly - always use gpuBench
    %   to create the data.
    %
    %   See also: gpuBench
    
    %   Copyright 2011-2021 The MathWorks, Inc.
    
    properties
        IsSelected
    end
    
    properties (SetAccess=immutable)
        MATLABRelease
        CPUInfo
        GPUInfo
        IsHostData
        Timestamp
    end
    
    properties (Dependent)
        NativelySupported
    end
    
    properties (SetAccess=private)
        Results
    end
    
    properties (Access=private, Constant)
        Version = 1
    end
    
    methods
        function obj = PerformanceData( release, cpuinfo, gpuinfo, isHostData, timestamp )
            % Construct a new performance data object
            obj.MATLABRelease = release;
            obj.CPUInfo = cpuinfo;
            obj.GPUInfo = gpuinfo;
            obj.Results = struct( ...
                'FunctionName', {}, ...
                'DataType', {}, ...
                'Sizes', {}, ...
                'NumOps', {}, ...
                'Times', {} );
            obj.IsSelected = false;
            obj.IsHostData = isHostData;
            obj.Timestamp = timestamp;
        end % constructor
        
        function obj = addResult( obj, fcnName, datatype, sizes, numops, times )
            N = numel( obj.Results );
            obj.Results(N+1,1).FunctionName = fcnName;
            obj.Results(N+1,1).DataType = datatype;
            obj.Results(N+1,1).Sizes = sizes;
            obj.Results(N+1,1).NumOps = numops;
            obj.Results(N+1,1).Times = times;
        end % addResult
        
        function out = hasResult( obj, fcnname, datatype )
            if nargin<3
                % Name may be 'fcn (type)'
                [fcnname,datatype] = iSplitName( fcnname );
            end
            nameMatches = ismember( {obj.Results.FunctionName}, fcnname );
            typeMatches = ismember( {obj.Results.DataType}, datatype );
            out = any( nameMatches & typeMatches );
        end % hasResult
        
        function out = getResult( obj, fcnname, datatype )
            if nargin<3
                % Name may be 'fcn (type)'
                [fcnname,datatype] = iSplitName( fcnname );
            end
            nameMatches = ismember( {obj.Results.FunctionName}, fcnname );
            typeMatches = ismember( {obj.Results.DataType}, datatype );
            idx = find( nameMatches & typeMatches, 1, 'first' );
            if isempty( idx )
                error( 'GPUBench:PerformanceData:NoSuchData', 'No results were found for %s (%s).', ...
                    fcnname, datatype );
            end
            out = obj.Results(idx);
        end % getResult
        
        function name = getDeviceName( obj )
            if obj.IsHostData
                name = obj.CPUInfo.Name;
            else
                name = obj.GPUInfo.Name;
            end
        end
        
        function filename = getDefaultJSONFilename( obj )
            devname = strrep(obj.getDeviceName(), ' ', '_');
            filename = strcat(devname, '.gpubench.json');
        end
        
        function writeAsJSON( obj, filename )
            ws = warning('Query', 'MATLAB:structOnObject');
            restoreWarning = onCleanup( @() warning(ws) );
            
            % Convert to struct and set NumOps to uint64 to avoid
            % truncation in scientific format.
            warning('off', 'MATLAB:structOnObject');
            objStruct = struct(obj);
            for ii=1:numel(objStruct.Results)
                objStruct.Results(ii).Sizes = uint64(objStruct.Results(ii).Sizes);
                objStruct.Results(ii).NumOps = uint64(objStruct.Results(ii).NumOps);
            end
            js = jsonencode(objStruct);
            
            fid = fopen(filename, 'wt');
            if fid<=0
                error( 'GPUBench:PerformanceData:WriteOpenFile', ...
                    'Cannot open file for writing: %s.', ...
                    filename );
            end
            cleaner = onCleanup( @() fclose(fid) );
            
            % Title
            fwrite(fid, js);
        end
        
        function tf = get.NativelySupported(obj)
            if obj.IsHostData
                tf = true;
            else
                [minCC, maxCC] = gpubench.getSupportedComputeCapabilityForRelease(obj.MATLABRelease);
                myCC = str2double(obj.GPUInfo.ComputeCapability);
                tf = (myCC >= minCC) && (myCC <= maxCC);
            end
        end
    end
    
    methods(Static)
        function obj = readFromJSON( filename )
            fid = fopen(filename, 'rt');
            if fid<=0
                error('GPUBench:PerformanceData:ReadOpenFile', ...
                    'Cannot open file for reading: %s.', filename);
            end
            cleaner = onCleanup( @() fclose(fid) );
            
            jsonTxt = fgets(fid);
            objStruct = jsondecode(jsonTxt);
            
            % Check the version
            if ~isfield(objStruct, 'Version') || objStruct.Version ~= 1
                error('GPUBench:PerformanceData:BadVersion', ...
                    'Incorrect version in file: %s.', filename);
            end
            
            % Now build the object
            obj = gpubench.PerformanceData( ...
                objStruct.MATLABRelease, ...
                objStruct.CPUInfo, ...
                objStruct.GPUInfo, ...
                objStruct.IsHostData, ...
                objStruct.Timestamp );
            
            % Set additional fields, converting size and NumObs to double
            % (stored as uint64 to avoid truncation)
            for ii=1:numel(objStruct.Results)
                objStruct.Results(ii).Sizes = double(objStruct.Results(ii).Sizes);
                objStruct.Results(ii).NumOps = double(objStruct.Results(ii).NumOps);
            end
            obj.Results = objStruct.Results;
        end
    end
    
end

function [fcnname,datatype] = iSplitName( longname )
% Split a long name 'fcn (datatype)' into its component name and type
out = regexp( longname, '(?<fcn>\w+)\s+\((?<type>\w+)\)', 'names' );
fcnname = out.fcn;
datatype = out.type;
end
