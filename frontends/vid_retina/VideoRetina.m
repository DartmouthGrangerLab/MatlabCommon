%Eli Bowen
%5/3/2020
%wrapper around JavaCommon's VideoRetina class
%which is a wrapper around some functionality from an old version of OpenCV
%which implements:
%Benoit A., Caplier A., Durette B., Herault, J., "USING HUMAN VISUAL SYSTEM MODELING FOR BIO-INSPIRED LOW LEVEL IMAGE PROCESSING", Computer Vision and Image Understanding 114 (2010)
%https://docs.opencv.org/trunk/dc/d54/classcv_1_1bioinspired_1_1Retina.html
%TODO: consider using mexopencv or matlab's opencv module, which should be faster if either actually works (never tried)
%       or do a matlab reimplementation of opencv_contrib/modules/bioinspired, which should be even fasterer (https://github.com/opencv/opencv_contrib/tree/master/modules/bioinspired/src)
classdef VideoRetina < handle
    properties (SetAccess = protected)
        retina(1,1)
        nRows(1,1)
        nCols(1,1)
        isColor(1,1) logical
    end
    
    
    methods
        %constructor
        function [obj] = VideoRetina (nRows, nCols, isColor)
            obj.nRows = nRows;
            obj.nCols = nCols;
            obj.isColor = isColor;
            
            [rootPath,~,~] = fileparts(mfilename('fullpath')); % jars expected in same folder as VideoRetina.m (should be MatlabCommon/frontends/vid_retina/)
            if isempty(StringFind(javaclasspath(), fullfile(rootPath, 'JavaCommon.jar'), true)) % for performance
                javaaddpath(fullfile(rootPath, 'JavaCommon.jar')); % for VideoRetina
            end
            if isempty(StringFind(javaclasspath(), fullfile(rootPath, 'javacpp.jar'), true)) % for performance
                javaaddpath(fullfile(rootPath, 'javacpp.jar')); % for VideoRetina
            end
            if isempty(StringFind(javaclasspath(), fullfile(rootPath, 'javacv.jar'), true)) % for performance
                javaaddpath(fullfile(rootPath, 'javacv.jar')); % for VideoRetina
            end
            if isempty(StringFind(javaclasspath(), fullfile(rootPath, 'opencv.jar'), true)) % for performance
                javaaddpath(fullfile(rootPath, 'opencv.jar')); % for VideoRetina
            end
            obj.retina = common.video.VideoRetina(obj.nRows, obj.nCols, obj.isColor); % prints lots of junk
        end
        
        
        %INPUTS:
        %   img - can be double (range 0-->1) or uint8 (range 0-->255)
        %           return value will be the same type and range
        function [parvo,magno] = ProcessFrame (obj, img)
            assert(size(img, 1) == obj.nRows && size(img, 2) == obj.nCols);
            if isa(img, 'uint8')
                dataType = 1;
            elseif isa(img, 'double')
                assert(all(img(:) >= 0) && all(img(:) <= 1));
                img = floor(img .* 255);
                dataType = 2;
            else
                error('unsupported datatype for img');
            end
            
            img = obj.Int2Unsigned(img);
            
            if obj.isColor
                assert(size(img, 3) == 3);
                frameBI = common.utils.ImageUtils.Color2BufferedImage(img, 255);
            else
                assert(size(img, 3) == 1);
%                 frameBI = common.utils.ImageUtils.Grayscale2SingleChannelBufferedImage(img); % converts grayscale matrix to grayscale BufferedImage
                % due to some bug, retina code outputs the same thing for magno and parvo if we use above; must use below
                frameBI = common.utils.ImageUtils.Grayscale2BufferedImage(img, 255); % converts grayscale matrix to RGB BufferedImage
            end
            
            obj.retina.ProcessFrame(frameBI);
            
            parvoBI = obj.retina.getParvo(); % java BufferedImage
            if obj.isColor
                assert(parvoBI.getColorModel().getNumComponents() == 3);
                parvo = obj.Unsigned2Int(common.utils.ImageUtils.BufferedImage2Color(parvoBI)); % now an int32 in range 0-->255
            else
                assert(parvoBI.getColorModel().getNumComponents() == 1);
                parvo = obj.Unsigned2Int(common.utils.ImageUtils.BufferedImage2Grayscale(parvoBI)); % now an int32 in range 0-->255
            end
            
            magnoBI = obj.retina.getMagno(); % java BufferedImage
            assert(magnoBI.getColorModel().getNumComponents() == 1);
            magno = obj.Unsigned2Int(common.utils.ImageUtils.BufferedImage2Grayscale(magnoBI)); % now an int32 in range 0-->255
            
            if dataType == 1 % uint8
                parvo = uint8(parvo);
                magno = uint8(magno);
            elseif dataType == 2 % double
                parvo = double(parvo) ./ 255;
                magno = double(magno) ./ 255;
            end
        end
        
        
        function [] = ClearBuffers (obj)
            obj.retina.ClearBuffers();
        end
        
        
        %MAGNO PARAMETERS (except for logicals, pass [] or -1 to leave as default):
        %   normaliseOutput - boolean (DEFAULT = true) specifies if (true) output is rescaled between 0 and 255 or not (false)
        %   parasolCells_beta - single float (DEFAULT = 0) the low pass filter gain used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), typical value is 0
        %   parasolCells_tau - single float (DEFAULT = 0) the low pass filter time constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is frame, typical value is 0 (immediate response)
        %   parasolCells_k - single float (DEFAULT = 7) the low pass filter spatial constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is pixels, typical value is 5
        %   amacriCellsTemporalCutFrequency - single float (DEFAULT = 1.2) the time constant of the first order high pass fiter of the magnocellular way (motion information channel), unit is frames, typical value is 1.2
        %   V0CompressionParameter - single float (DEFAULT = 0.95) the compression strengh of the ganglion cells local adaptation output, set a value between 0.6 and 1 for best results, a high value increases more the low value sensitivity... and the output saturates faster, recommended value: 0.95
        %   localAdaptintegration_tau - single float (DEFAULT = 0) specifies the temporal constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation
        %   localAdaptintegration_k - single float (DEFAULT = 7) specifies the spatial constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation 
        function [] = SetMagnoParams (obj, normaliseOutput, parasolCells_beta, parasolCells_tau, parasolCells_k, amacriCellsTemporalCutFrequency, V0CompressionParameter, localAdaptintegration_tau, localAdaptintegration_k)
            validateattributes(normaliseOutput, {'logical'}, {'nonempty','scalar'});
            validateattributes(parasolCells_beta, {'numeric'}, {'scalar'});
            if isempty(parasolCells_beta)
                parasolCells_beta = -1;
            end
            validateattributes(parasolCells_tau, {'numeric'}, {'scalar'});
            if isempty(parasolCells_tau)
                parasolCells_tau = -1;
            end
            validateattributes(parasolCells_k, {'numeric'}, {'scalar'});
            if isempty(parasolCells_k)
                parasolCells_k = -1;
            end
            validateattributes(amacriCellsTemporalCutFrequency, {'numeric'}, {'scalar'});
            if isempty(amacriCellsTemporalCutFrequency)
                amacriCellsTemporalCutFrequency = -1;
            end
            validateattributes(V0CompressionParameter, {'numeric'}, {'scalar'});
            if isempty(V0CompressionParameter)
                V0CompressionParameter = -1;
            end
            validateattributes(localAdaptintegration_tau, {'numeric'}, {'scalar'});
            if isempty(localAdaptintegration_tau)
                localAdaptintegration_tau = -1;
            end
            validateattributes(localAdaptintegration_k, {'numeric'}, {'scalar'});
            if isempty(localAdaptintegration_k)
                localAdaptintegration_k = -1;
            end
            obj.retina.SetMagnoParams(normaliseOutput, single(parasolCells_beta), single(parasolCells_tau), single(parasolCells_k), single(amacriCellsTemporalCutFrequency), single(V0CompressionParameter), single(localAdaptintegration_tau), single(localAdaptintegration_k));
        end
        
        
        %PARVO PARAMETERS (except for logicals, pass [] or -1 to leave as default):
        %   colorMode - boolean (DEFAULT = true) specifies if (true) color is processed of not (false) to then processing gray level image
        %   normaliseOutput - boolean (DEFAULT = true) specifies if (true) output is rescaled between 0 and 255 of not (false)
        %   photoreceptorsLocalAdaptationSensitivity - single float (DEFAULT = 0.7) the photoreceptors sensitivity renage is 0-1 (more log compression effect when value increases)
        %   photoreceptorsTemporalConstant - single float (DEFAULT = 0.5) the time constant of the first order low pass filter of the photoreceptors, use it to cut high temporal frequencies (noise or fast motion), unit is frames, typical value is 1 frame
        %   photoreceptorsSpatialConstant - single float (DEFAULT = 0.53) the spatial constant of the first order low pass filter of the photoreceptors, use it to cut high spatial frequencies (noise or thick contours), unit is pixels, typical value is 1 pixel
        %   horizontalCellsGain - single float (DEFAULT = 0) gain of the horizontal cells network, if 0, then the mean value of the output is zero, if the parameter is near 1, then, the luminance is not filtered and is still reachable at the output, typicall value is 0
        %   HcellsTemporalConstant - single float (DEFAULT = 1) the time constant of the first order low pass filter of the horizontal cells, use it to cut low temporal frequencies (local luminance variations), unit is frames, typical value is 1 frame, as the photoreceptors
        %   HcellsSpatialConstant - single float (DEFAULT = 7) the spatial constant of the first order low pass filter of the horizontal cells, use it to cut low spatial frequencies (local luminance), unit is pixels, typical value is 5 pixel, this value is also used for local contrast computing when computing the local contrast adaptation at the ganglion cells level (Inner Plexiform Layer parvocellular channel model)
        %   ganglionCellsSensitivity - single float (DEFAULT = 0.7) the compression strengh of the ganglion cells local adaptation output, set a value between 0.6 and 1 for best results, a high value increases more the low value sensitivity... and the output saturates faster, recommended value: 0.7 
        function [] = SetParvoParams (obj, colorMode, normaliseOutput, photoreceptorsLocalAdaptationSensitivity, photoreceptorsTemporalConstant, photoreceptorsSpatialConstant, horizontalCellsGain, HcellsTemporalConstant, HcellsSpatialConstant, ganglionCellsSensitivity)
            validateattributes(colorMode, {'logical'}, {'nonempty','scalar'});
            validateattributes(normaliseOutput, {'logical'}, {'nonempty','scalar'});
            validateattributes(photoreceptorsLocalAdaptationSensitivity, {'numeric'}, {'scalar'});
            if isempty(photoreceptorsLocalAdaptationSensitivity)
                photoreceptorsLocalAdaptationSensitivity = -1;
            end
            validateattributes(photoreceptorsTemporalConstant, {'numeric'}, {'scalar'});
            if isempty(photoreceptorsTemporalConstant)
                photoreceptorsTemporalConstant = -1;
            end
            validateattributes(photoreceptorsSpatialConstant, {'numeric'}, {'scalar'});
            if isempty(photoreceptorsSpatialConstant)
                photoreceptorsSpatialConstant = -1;
            end
            validateattributes(horizontalCellsGain, {'numeric'}, {'scalar'});
            if isempty(horizontalCellsGain)
                horizontalCellsGain = -1;
            end
            validateattributes(HcellsTemporalConstant, {'numeric'}, {'scalar'});
            if isempty(HcellsTemporalConstant)
                HcellsTemporalConstant = -1;
            end
            validateattributes(HcellsSpatialConstant, {'numeric'}, {'scalar'});
            if isempty(HcellsSpatialConstant)
                HcellsSpatialConstant = -1;
            end
            validateattributes(ganglionCellsSensitivity, {'numeric'}, {'scalar'});
            if isempty(ganglionCellsSensitivity)
                ganglionCellsSensitivity = -1;
            end
            obj.retina.SetParvoParams(colorMode, normaliseOutput, single(photoreceptorsLocalAdaptationSensitivity), single(photoreceptorsTemporalConstant), single(photoreceptorsSpatialConstant), single(horizontalCellsGain), single(HcellsTemporalConstant), single(HcellsSpatialConstant), single(ganglionCellsSensitivity));
        end
    end
    
    
    methods (Access = private)
        %COPIED from JavaCommon's common.utils.DataUtils
        %this data type code is a mess because opencv uses signed bytes to represent unsigned integers...
        %ASSUMES the integer is in the range of (0, 255).
        %INPUTS:
        %   data - of "int" type in java
        function [data] = Int2Unsigned (obj, data)
%             assert(isa(data, 'int32')); % meh don't check
            
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
    