%Eli Bowen
%5/3/2020
%wrapper around JavaCommon's VideoRetina class
%which is a wrapper around some functionality from an old version of OpenCV
%which implements:
%Benoit A., Caplier A., Durette B., Herault, J., "USING HUMAN VISUAL SYSTEM MODELING FOR BIO-INSPIRED LOW LEVEL IMAGE PROCESSING", Computer Vision and Image Understanding 114 (2010)
classdef VideoRetina < handle
    properties (SetAccess = protected)
        retina
        numRows(1,1) double
        numCols(1,1) double
        isInFullColor(1,1) logical
    end
    
    
    methods
        function [obj] = VideoRetina (numRows, numCols, isInFullColor) %constructor
            obj.numRows = numRows;
            obj.numCols = numCols;
            obj.isInFullColor = isInFullColor;
            
            if isempty(StringFind(javaclasspath(), '/ihome/ebowen/workspace/JavaCommon/JavaCommon.jar', true)) %for performance
                javaaddpath('/ihome/ebowen/workspace/JavaCommon/JavaCommon.jar'); %for VideoRetina
            end
            if isempty(StringFind(javaclasspath(), '/ihome/ebowen/workspace/JavaCommon/javacv/javacpp.jar', true)) %for performance
                javaaddpath('/ihome/ebowen/workspace/JavaCommon/javacv/javacpp.jar'); %for VideoRetina
            end
            if isempty(StringFind(javaclasspath(), '/ihome/ebowen/workspace/JavaCommon/javacv/javacv.jar', true)) %for performance
                javaaddpath('/ihome/ebowen/workspace/JavaCommon/javacv/javacv.jar'); %for VideoRetina
            end
            obj.retina = common.video.VideoRetina(obj.numRows, obj.numCols, obj.isInFullColor); %prints lots of junk
        end
        
        
        %INPUTS:
        %   img - can be double (range 0-->1) or uint8 (range 0-->255)
        %           return value will be the same type and range
        function [parvo,magno] = ProcessFrame (obj, img)
            assert(size(img, 1) == obj.numRows && size(img, 2) == obj.numCols);
            if isa(img, 'uint8')
                dataType = 1;
            elseif isa(img, 'double')
                assert(all(img(:) >= 0) && all(img(:) <= 1));
                img = floor(img .* 255); %floor will be called implicitly
                dataType = 2;
            else
                error('invalid datatype for img');
            end
            
            img = obj.Int2Unsigned(img);
            obj.retina.ProcessFrame(common.utils.ImageUtils.Color2BufferedImage(img, 255));
            parvo = obj.Unsigned2Int(common.utils.ImageUtils.BufferedImage2Color(obj.retina.getParvo())); %now an int32 in range 0-->255
            magno = obj.Unsigned2Int(common.utils.ImageUtils.BufferedImage2Color(obj.retina.getMagno())); %now an int32 in range 0-->255
            
            if dataType == 1 %uint8
                parvo = uint8(parvo);
                magno = uint8(magno);
            elseif dataType == 2 %double
                parvo = double(parvo) ./ 255;
                magno = double(magno) ./ 255;
            end
        end
    end
    
    
    methods (Access = private)
        %COPIED from JavaCommon's common.utils.DataUtils
        %this data type code is a mess because opencv uses signed bytes to represent unsigned integers...
        %ASSUMES the integer is in the range of (0, 255).
        %INPUTS:
        %   data - of "int" type in java
        function [data] = Int2Unsigned (obj, data)
%             assert(isa(data, 'int32')); %meh don't check
            
            data(data > 127) = data(data > 127) - 256;
            data = int8(data);
        end
        
        
        %COPIED from JavaCommon's common.utils.DataUtils
        %this data type code is a mess because opencv uses signed bytes to represent unsigned integers...
        %Reads the byte as though it were an unsigned byte, and returns it's value as an integer.
        %The result will be in the range (0, 255).
        %INPUTS:
        %   b - of "byte" type in java
        function [data] = Unsigned2Int (obj, data)
            assert(isa(data, 'int8'));
            
            data = int32(data);
            data(data < 0) = data(data < 0) + int32(255);
        end
    end
end
    