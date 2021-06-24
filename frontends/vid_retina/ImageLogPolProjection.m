% Author: Tracey E. Mills, Granger Lab at Dartmouth
% This code is a translated and enhanced version of c++ code by:
% Alexandre Benoit (benoit.alexandre.vision@gmail.com), LISTIC lab, Annecy le vieux, France (maintained by Listic lab www.listic.univ-savoie.fr and Gipsa Lab www.gipsa-lab.inpg.fr)
% Benoit A., Caplier A., Durette B., Herault, J., "USING HUMAN VISUAL SYSTEM MODELING FOR BIO-INSPIRED LOW LEVEL IMAGE PROCESSING", Elsevier, Computer Vision and Image Understanding 114 (2010), pp. 758-773, DOI: http://dx.doi.org/10.1016/j.cviu.2010.01.011
% see also: Vision: Images, Signals and Neural Networks: Models of Neural Processing in Visual Perception (Progress in Neural Processing),By: Jeanny Herault, ISBN: 9814273686. WAPI (Tower ID): 113266891.
% retinacolor.m originates from: B. Chaix de Lavarene, D. Alleysson, B. Durette, J. Herault (2007). "Efficient demosaicing through recursive filtering", IEEE International Conference on Image Processing ICIP 2007
% imagelogpolprojection.m originates from: Barthelemy Durette phd with Jeanny Herault. A Retina / V1 cortex projection is also proposed and originates from Jeanny's discussions.
% Copyright (C) 2007-2011, LISTIC Lab, Annecy le Vieux and GIPSA Lab, Grenoble, France, all rights reserved.
% Copyright (C) 2020-2021 Granger Lab
%
% Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
%
% * Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%
% * Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% * The name of the copyright holders may not be used to endorse or promote products derived from this software without specific prior written permission.
%
% This software is provided by the copyright holders and contributors "as is" and
% any express or implied warranties, including, but not limited to, the implied
% warranties of merchantability and fitness for a particular purpose are disclaimed.
% In no event shall the Intel Corporation or contributors be liable for any direct,
% indirect, incidental, special, exemplary, or consequential damages
% (including, but not limited to, procurement of substitute goods or services;
% loss of use, data, or profits; or business interruption) however caused
% and on any theory of liability, whether in contract, strict liability,
% or tort (including negligence or otherwise) arising in any way out of
% the use of this software, even if advised of the possibility of such damage.


classdef ImageLogPolProjection < BasicRetinaFilter
    properties (SetAccess = private)
        selectedProjection(1,1) % enum PROJECTIONTYPE{RETINALOGPROJECTION, CORTEXLOGPOLARPROJECTION};

        % size of the image output
        outputNBrows(1,1)
        outputNBcolumns(1,1)
        outputNBpixels(1,1)

        colorModeCapable(1,1) logical % is the object able to manage color flag
        samplingStrength(1,1) double % sampling strength factor
        reductionFactor(1,1) double % sampling reduction factor

        % log sampling parameters
        azero(1,1) double
        alim(1,1) double
        minDimension(1,1) double

        % template buffers
        sampledFrame
        tempBuffer

        irregularLPfilteredFrame % just a reference for easier understanding
        usefullpixelIndex(1,1)

        % init transformation tables
        computeLogProjection(1,1) logical
        computeLogPolarProjection(1,1) logical
        
        %handles mapping of pixel position from input to output frame
        %pixel value at input(oldPixelRow(i), oldPixelCol(i)) is mapped to output(newPixelRow(i), newPixelCol(i))
        newPixelRow
        newPixelCol
        oldPixelRow
        oldPixelCol

        initOK(1,1) logical % specifies if init was done yet
    end
    
    
    methods
        % constructor, just specifies the image input size and the projection type, no projection initialisation is done
        % -> use initLogRetinaSampling() or initLogPolarCortexSampling() for that
        % @param nRows: number of rows of the input image
        % @param nCols: number of columns of the input image
        % @param projection - scalar int (enum) the type of projection, 1 = RETINALOGPROJECTION 2 = CORTEXLOGPOLARPROJECTION
        % @param colorModeCapable - scalar logical specifies if the projection is applied on a grayscale image (false) or color images (3 layers) (true)
        % constructor
        function [obj] = ImageLogPolProjection (nRows, nCols, projection, colorModeCapable)
            obj = obj@BasicRetinaFilter(nRows, nCols, projection, colorModeCapable);
            obj.nRows = nRows;
            obj.nCols = nCols;
            obj.selectedProjection = projection;
            obj.reductionFactor = 0;
            obj.initOK = false;
            obj.colorModeCapable = colorModeCapable;
            if obj.colorModeCapable
                obj.tempBuffer = zeros(nRows, nCols, 3);
                obj.sampledFrame = zeros(nRows, nCols, 3);
            else
                obj.tempBuffer = zeros(nRows, nCols);
                obj.sampledFrame = zeros(nRows, nCols);
            end
            obj.irregularLPfilteredFrame = zeros(nRows, nCols);

            obj.clearAllBuffers();
        end

        % function that clears all buffers of the object
        function [] = clearAllBuffers (obj)
            clearAllBuffers@BasicRetinaFilter(obj);
            obj.sampledFrame(:) = 0;
            obj.tempBuffer(:)   = 0;
        end

        % init function depending on the projection type
        % @param reductionFactor - scalar double, the size reduction factor of the ouptup image in regard of the size of the input image
        % @param samplingStrength - scalar double, specifies the strength of the log compression effect (magnifying coefficient)
        % @return true if the init was performed without any errors
        % init functions depending on the projection type
        function [] = initProjection (obj, reductionFactor, samplingStrength)
            if obj.selectedProjection == 1 % RETINALOGPROJECTION
                obj.initLogRetinaSampling(reductionFactor, samplingStrength);
            elseif obj.selectedProjection == 2 % CORTEXLOGPOLARPROJECTION
                obj.initLogPolarCortexSampling(reductionFactor, samplingStrength);
            else
                disp('ImageLogPolProjection::no projection set up... performing default retina projection');
                obj.initLogRetinaSampling(reductionFactor, samplingStrength);
            end
        end

        % main funtion of the class: run projection function
        % @param inputFrame: the input frame to be processed
        % @param colorMode - scalar logical, the input buffer color mode: false=gray levels, true = color
        % action function
        function [] = runProjection (obj, inputFrame, isColor)
            if obj.colorModeCapable && isColor
                % progressive filtering and storage of the result in tempBuffer
                obj.irregularLPfilteredFrame = obj.spatiotemporalLPfilter_Irregular(inputFrame(:,:,1), obj.irregularLPfilteredFrame, 1);
                obj.tempBuffer(:,:,1) = obj.spatiotemporalLPfilter_Irregular(obj.irregularLPfilteredFrame, obj.tempBuffer(:,:,1), 1); % warning, temporal issue may occur, if the temporal constant is not NULL !!!

                obj.irregularLPfilteredFrame = obj.spatiotemporalLPfilter_Irregular(inputFrame(:,:,2), obj.irregularLPfilteredFrame, 1);
                obj.tempBuffer(:,:,2) = obj.spatiotemporalLPfilter_Irregular(obj.irregularLPfilteredFrame, obj.tempBuffer(:,:,2), 1);

                obj.irregularLPfilteredFrame = obj.spatiotemporalLPfilter_Irregular(inputFrame(:,:,3), obj.irregularLPfilteredFrame, 1);
                obj.tempBuffer(:,:,3) = obj.spatiotemporalLPfilter_Irregular(obj.irregularLPfilteredFrame, obj.tempBuffer(:,:,3), 1);

                % applying image projection/resampling
                for i=1:size(obj.oldPixelRow, 2)
                    obj.sampledFrame(obj.oldPixelRow(i), obj.oldPixelCol(i), 1) = obj.tempBuffer(obj.newPixelRow(i), obj.newPixelCol(i), 1);
                    obj.sampledFrame(obj.oldPixelRow(i), obj.oldPixelCol(i), 2) = obj.tempBuffer(obj.newPixelRow(i), obj.newPixelCol(i), 2);
                    obj.sampledFrame(obj.oldPixelRow(i), obj.oldPixelCol(i), 3) = obj.tempBuffer(obj.newPixelRow(i), obj.newPixelCol(i), 3);
                end
            else
                obj.irregularLPfilteredFrame = obj.spatiotemporalLPfilter_Irregular(inputFrame, obj.irregularLPfilteredFrame, 1);
                obj.sampledFrame = obj.irregularLPfilteredFrame;
                obj.irregularLPfilteredFrame = obj.spatiotemporalLPfilter_Irregular(obj.irregularLPfilteredFrame, obj.irregularLPfilteredFrame, 1);
                
                for i=1:size(obj.oldPixelRow, 2)
                    obj.sampledFrame(obj.oldPixelRow(i), obj.oldPixelCol(i)) = obj.irregularLPfilteredFrame(obj.newPixelRow(i), obj.newPixelCol(i));
                end
            end
        end
        
        %% gets
        
        % @return the numbers of rows (height) of the output image
        function [retVal] = getOutputNBrows (obj)
            retVal = obj.outputNBrows;
        end
        % @return the numbers of columns (width) of the output image
        function [retVal] = getOutputNBcolumns (obj)
            retVal = obj.outputNBcolumns;
        end
        % @return the output of the filter which applies an irregular Low Pass spatial filter to the image input
        function [retVal] = getIrregularLPfilteredInputFrame (obj)
            retVal = obj.irregularLPfilteredFrame;
        end
        % function which retrieves the output frame which was updated after the "runProjection(...) function in BasicRetinaFilter::runProgressiveFilter(...)
        function [retVal] = getSampledFrame (obj)
            retVal = obj.sampledFrame;
        end

        function [retVal] = getOriginalRadiusLength (obj, projectedRadiusLength)
            retVal = obj.azero / (obj.alim - projectedRadiusLength * 2 / obj.minDimension);
        end
    end
    
    
    methods (Access = private)
        %% private init projections functions called by "initProjection(...)" function

        % -> private init functions dedicated to each projection
        function [] = initLogRetinaSampling (obj, reductionFactor, samplingStrength)
            obj.initOK = false;

            if obj.selectedProjection ~= 1 % RETINALOGPROJECTION
                error('could not initialize logPolar projection for a log projection system -> you probably chose the wrong init function, use initLogPolarCortexSampling() instead');
            end
            if reductionFactor < 1
                error('reduction factor must be greater than 1');
            end

            % compute image output size
            obj.outputNBrows = obj.nRows / reductionFactor; % output size of this object
            obj.outputNBcolumns = obj.nCols / reductionFactor; % output size of this object
            obj.outputNBpixels = obj.outputNBrows * obj.outputNBcolumns;

            % setup progressive prefilter that will be applied BEFORE log sampling
            obj.setProgressiveFilterConstants_CentredAccuracy(0, 0, 0.99, 1);

            % specifiying new reduction factor after preliminar checks
            obj.reductionFactor = reductionFactor;
            obj.samplingStrength = samplingStrength;

            % compute the rlim for symetric rows/columns sampling, then, the rlim is based on the smallest dimension
            obj.minDimension = min(size(obj.filterOutput, 1), size(obj.filterOutput, 2));

            % input frame dimensions dependent log sampling:
%             rlim = 1 / reductionFactor * (obj.minDimension/2+samplingStrength);

            % input frame dimensions INdependent log sampling:
            obj.azero = (1 + reductionFactor*sqrt(samplingStrength)) / (reductionFactor*reductionFactor*samplingStrength-1);
            obj.alim = (1 + obj.azero) / reductionFactor;

            % get half frame size
            halfOutputRows = obj.outputNBrows / 2;
            halfOutputColumns = obj.outputNBcolumns / 2;
            halfInputRows = size(obj.filterOutput, 1) / 2;
            halfInputColumns = size(obj.filterOutput, 2) / 2;
            
            %oldPixelRow/Col hold row and column numbers, respectively, of pixel
            %coordinates in the input image
            %newPixelRow/Col hold row and column numbers, respectively, of
            %new coordinates for pixel value at oldPixelRow(i), oldPixelCol(i)
            obj.oldPixelRow = zeros(1, size(obj.filterOutput, 2));
            obj.oldPixelCol = zeros(1, size(obj.filterOutput, 2));
            obj.newPixelRow = zeros(1, size(obj.filterOutput, 2));
            obj.newPixelCol = zeros(1, size(obj.filterOutput, 2));
            i=1;
            rMax = (obj.minDimension/2)*(obj.minDimension/2);

            for r=0:halfOutputRows-1
                for c=0:halfOutputColumns-1
                    % get the pixel position in the original picture

                    % -> input frame dimensions dependent log sampling:
%                     scale = samplingStrength / (rlim - sqrt(r^2 + c^2));

                    % -> input frame dimensions INdependent log sampling:
                    scale = obj.getOriginalRadiusLength(sqrt(r^2 + c^2));
                    if scale < 0 % check it later
                        scale = 10000;
                    end

                    u = floor(r * scale);
                    v = floor(c * scale);

                    % manage border effects
                    len = u*u + v*v; % length
                    radiusRatio = sqrt(rMax / len);
                    if radiusRatio < 1
                        u = floor(radiusRatio * u);
                        v = floor(radiusRatio * v);
                    end
                    if (u <= halfInputRows) && (v <= halfInputColumns)
                        % set pixel coordinate of the input picture at the current log sampled pixel
                        % 1st quadrant
                        obj.oldPixelCol(i) = halfOutputColumns+c;
                        obj.oldPixelRow(i) = halfOutputRows-r;
                        obj.newPixelCol(i) = halfInputColumns+v;
                        obj.newPixelRow(i) = halfInputRows-u;
                        i = i+1;
                        % 2nd quadrant
                        obj.oldPixelCol(i) = halfOutputColumns+c;
                        obj.oldPixelRow(i) = halfOutputRows+r;
                        obj.newPixelCol(i) = halfInputColumns+v;
                        obj.newPixelRow(i) = halfInputRows+u;
                        i = i+1;
                        % 3rd quadrant
                        obj.oldPixelCol(i) = halfOutputColumns-c;
                        obj.oldPixelRow(i) = halfOutputRows-r;
                        obj.newPixelCol(i) = halfInputColumns-v;
                        obj.newPixelRow(i) = halfInputRows-u;
                        i = i+1;
                        % 4th quadrant
                        obj.oldPixelCol(i) = halfOutputColumns-c;
                        obj.oldPixelRow(i) = halfOutputRows+r;
                        obj.newPixelCol(i) = halfInputColumns-v;
                        obj.newPixelRow(i) = halfInputRows+u;
                        i = i+1;
                    end
                end
            end

            obj.clearAllBuffers();

            obj.initOK = true;
        end

        function [] = initLogPolarCortexSampling (obj, reductionFactor)
            obj.initOK = false;

            if obj.selectedProjection ~= 2 % CORTEXLOGPOLARPROJECTION
                error('could not initialize log projection for a logPolar projection system -> you probably chose the wrong init function, use initLogRetinaSampling() instead');
            end

            if reductionFactor < 1
                error('reduction factor must be greater than 1');
            end

            % compute the smallest image size
            obj.minDimension = min(size(obj.filterOutput, 1), size(obj.filterOutput, 2));
            % specifiying new reduction factor after preliminary checks
            obj.reductionFactor = reductionFactor;
            % compute image output size
            obj.outputNBrows = obj.minDimension / reductionFactor;
            obj.outputNBcolumns = obj.minDimension / reductionFactor;
            obj.outputNBpixels = obj.outputNBrows * obj.outputNBcolumns;

            halfInputRows = size(obj.filterOutput, 1) / 2 - 1;
            halfInputColumns = size(obj.filterOutput, 2) / 2 - 1;

            % setup progressive prefilter that will be applied BEFORE log sampling
            obj.setProgressiveFilterConstants_CentredAccuracy(0, 0, 0.99, 1);

            % (re)create the image output buffer if the reduction factor changed
            if obj.colorModeCapable
                obj.sampledFrame = zeros(obj.nRows, obj.nCols, 3);
            else
                obj.sampledFrame = zeros(obj.nRows, obj.nCols, 1);
            end

            % create the radius and orientation axis and fill them, radius E [0;1], orientation E[-pi, pi]
            radiusAxis = zeros(1, obj.outputNBcolumns);
            radiusStep = 2.30 / obj.outputNBcolumns;
            for i=1:obj.outputNBcolumns
                radiusAxis(i) = i * radiusStep;
            end
            orientationAxis = zeros(1, obj.outputNBrows);
            orientationStep = -2 * pi / obj.outputNBrows;
            for io=1:obj.outputNBrows
                orientationAxis(io) = io * orientationStep;
            end
            
            %oldPixelRow/Col hold row and column numbers, respectively, of pixel
            %coordinates in the input image
            %newPixelRow/Col hold row and column numbers, respectively, of
            %new coordinates for pixel value at oldPixelRow(i), oldPixelCol(i)
            obj.oldPixelRow = zeros(1, size(obj.filterOutput, 2));
            obj.oldPixelCol = zeros(1, size(obj.filterOutput, 2));
            obj.newPixelRow = zeros(1, size(obj.filterOutput, 2));
            obj.newPixelCol = zeros(1, size(obj.filterOutput, 2));
            i=1;
            % compute transformation, get theta and Radius in regard to the output sampled pixel
            diagonalLength = sqrt(obj.outputNBcolumns * obj.outputNBcolumns + obj.outputNBrows * obj.outputNBrows);
            for radiusIdx = 1:obj.outputNBcolumns
                for orientationIdx = 1:obj.outputNBrows
                    x = 1 + sinh(radiusAxis(radiusIdx)) * cos(orientationAxis(orientationIdx));
                    y = sinh(radiusAxis(radiusIdx)) * sin(orientationAxis(orientationIdx));
                    % get the input picture coordinate
                    R = diagonalLength * sqrt(x*x+y*y) / (5+sqrt(x*x+y*y));
                    theta = atan2(y, x);
                    % convert input polar coord into cartesian/C compatble coordinate
                    colIndex = ceil(cos(theta)*R) + halfInputColumns; %810
                    rowIndex = ceil(sin(theta)*R) + halfInputRows; %359
                    if (colIndex < size(obj.filterOutput, 2)) && (colIndex > 0) && (rowIndex < size(obj.filterOutput, 1)) && (rowIndex > 0)
                        % set coordinate
                        obj.oldPixelRow(i) = orientationIdx;
                        obj.oldPixelCol(i) = radiusIdx;
                        obj.newPixelRow(i) = rowIndex;
                        obj.newPixelCol(i) = colIndex;
                        i=i+1;
                     end
                end
            end

            obj.clearAllBuffers();
            
            obj.initOK = true;
        end
    end
end
