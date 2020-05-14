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
            
            if ~isempty(StringFind(javaclasspath(), '/ihome/ebowen/workspace/JavaCommon/JavaCommon.jar', true)) %for performance
                javaaddpath('/ihome/ebowen/workspace/JavaCommon/JavaCommon.jar'); %for VideoRetina
            end
            if ~isempty(StringFind(javaclasspath(), '/ihome/ebowen/workspace/JavaCommon/javacv/javacpp.jar', true)) %for performance
                javaaddpath('/ihome/ebowen/workspace/JavaCommon/javacv/javacpp.jar'); %for VideoRetina
            end
            if ~isempty(StringFind(javaclasspath(), '/ihome/ebowen/workspace/JavaCommon/javacv/javacv.jar', true)) %for performance
                javaaddpath('/ihome/ebowen/workspace/JavaCommon/javacv/javacv.jar'); %for VideoRetina
            end
            obj.retina = common.video.VideoRetina(obj.numRows, obj.numCols, obj.isInFullColor); %prints lots of junk
        end
        
        
        function [parvo,magno] = ProcessFrame (obj, img)
            assert(size(img, 1) == obj.numRows && size(img, 2) == obj.numCols);
            
            obj.retina.ProcessFrame(common.utils.ImageUtils.Color2BufferedImage(int8(img.*255 - 128), 255));
            parvo = double(common.utils.ImageUtils.BufferedImage2Color(obj.retina.getParvo())); %produces an int8
            magno = double(common.utils.ImageUtils.BufferedImage2Color(obj.retina.getMagno())); %produces an int8
            parvo(parvo < 0) = parvo(parvo < 0) + 255;
            magno(magno < 0) = magno(magno < 0) + 255; %convert from unsigned integer stuffed in an int8 to numbers 0 --> 255
            error('^validate');
        end
    end
end
    