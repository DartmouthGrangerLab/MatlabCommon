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
classdef RetinaColor < BasicRetinaFilter
    properties (SetAccess = private)
        % static values
        LMStoACr1Cr2 = [1,1,0,1,-1,0,-0.5,-0.5,1]
        LMStoLab = [0.5774,0.5774,0.5774,0.4082,0.4082,-0.8165,0.7071,-0.7071,0]

        samplingMethod
        saturateColors(1,1) logical
        colorSaturationValue(1,1)
        
        % links to parent buffers
        luminance
        multiplexedFrame
        
        % instance buffers
        colorSampling % table which specifies the color of each pixel
        RGBmosaic
        tempMultiplexedFrame
        demultiplexedTempBuffer
        demultiplexedColorFrame
        chrominance
        colorLocalDensity % buffer which contains the local density of the R, G and B photoreceptors for a normalization use
        imageGradient
        
        % probabilities of color R, G and B
        pR(1,1)
        pG(1,1)
        pB(1,1)
        
        objectInit(1,1) logical
    end
    
    methods

        % constructor of the retina color processing model
        % @param nRows: number of rows of the input image
        % @param nCols: number of columns of the input image
        % @param samplingMethod - scalar int (enum), the chosen color sampling method
        function [obj] = RetinaColor (nRows, nCols, samplingMethod)
            obj = obj@BasicRetinaFilter(nRows, nCols, 3, false);
            obj.colorSampling           = zeros(nRows, nCols);
            obj.RGBmosaic               = zeros(nRows, nCols, 3);
            obj.tempMultiplexedFrame    = zeros(nRows, nCols);
            obj.demultiplexedTempBuffer = zeros(nRows, nCols, 3);
            obj.demultiplexedColorFrame = zeros(nRows, nCols, 3);
            obj.chrominance             = zeros(nRows, nCols, 3);
            obj.colorLocalDensity       = zeros(nRows, nCols, 3);
            obj.imageGradient           = zeros(nRows, nCols, 2);
            
            % link to parent buffers
            obj.luminance = obj.filterOutput;
            obj.multiplexedFrame = zeros(nRows, nCols);

            obj.objectInit = false;
            obj.samplingMethod = samplingMethod;
            obj.saturateColors = false;
            obj.colorSaturationValue = 4;

            % set default spatio-temporal filter parameters
            obj.setLPfilterParameters(0, 0, 1.5, 1);
            obj.setLPfilterParameters(0, 0, 10.5, 2); % for the low pass filter dedicated to contours energy extraction (demultiplexing process)
            obj.setLPfilterParameters(0, 0, 0.9, 3);

            obj.imageGradient = 0.57; % init default value on image Gradient

            obj.initColorSampling(); % init color sampling map

            obj.clearAllBuffers();
        end

        % function that clears all buffers of the object
        function [] = clearAllBuffers (obj)
            clearAllBuffers@BasicRetinaFilter(obj);
            obj.tempMultiplexedFrame(:)    = 0;
            obj.demultiplexedTempBuffer(:) = 0;

            obj.demultiplexedColorFrame(:) = 0;
            obj.chrominance(:)             = 0;
            obj.imageGradient(:) = 0.5;
        end

        % color multiplexing function: a demultipleed RGB frame of size M*N*3 is transformed into a multiplexed M*N*1 pixels frame where each pixel is either Red, Green or Blue if using RGB images
        % @param demultiplexedInputFrame: the demultiplexed input frame to be processed of size M*N*3
        % @param multiplexedFrame: the resulting multiplexed frame
        % color multiplexing: input frame size=_NBrows*_filterOutput.getNBcolumns()*3, multiplexedFrame output size=_NBrows*_filterOutput.getNBcolumns()
        function [multiplexedFrame] = runColorMultiplexing(obj, demultiplexedInputFrame, valAssigned)
            % multiply each color layer by its bayer mask
            multiplexedFrame = zeros(size(obj.filterOutput, 1), size(obj.filterOutput, 2));
            multiplexedFrame(:) = demultiplexedInputFrame(obj.colorSampling(:));
            if ~valAssigned
                obj.multiplexedFrame = multiplexedFrame;
            end
        end

        % color demultiplexing function: a multiplexed frame of size M*N*1 pixels is transformed into a RGB demultiplexed M*N*3 pixels frame
        % @param multiplexedColorFrame: the input multiplexed frame to be processed
        % @param adaptiveFiltering - scalar logical, specifies if adaptive filtering is to be perform rather than standard filtering (adaptive filtering allows a better rendering)
        % @param maxInputValue - scalar double, the maximum input data value (should be 255 for 8 bits images but it can change in the case of High Dynamic Range Images (HDRI)
        % @return nothing, but the output demultiplexed frame is available by the use of the getDemultiplexedColorFrame() function, also use getLuminance() and getChrominance() in order to retreive either luminance or chrominance
        function [] = runColorDemultiplexing (obj, multiplexedColorFrame, adaptiveFiltering)
            obj.imageGradient = zeros(obj.nRows, obj.nCols);
            if ~exist('adaptiveFiltering', 'var') || isempty(adaptiveFiltering)
                adaptiveFiltering = false;
            end
            % demultiplex the grey frame to RGB frame
            % -> first set demultiplexed frame to 0
            obj.demultiplexedTempBuffer = zeros(size(obj.filterOutput, 1), size(obj.filterOutput, 2), 3);
            obj.demultiplexedTempBuffer(obj.colorSampling(:)) = multiplexedColorFrame(:);
            % interpolate the demultiplexed frame depending on the color sampling method
            if ~adaptiveFiltering
                obj.demultiplexedTempBuffer = obj.interpolateImageDemultiplexedImage(obj.demultiplexedTempBuffer);
            end
            % low pass filtering the demultiplexed frame
            obj.chrominance(:,:,1) = obj.spatiotemporalLPfilter(obj.demultiplexedTempBuffer(:,:,1), obj.chrominance(:,:,1), 1);
            obj.chrominance(:,:,2) = obj.spatiotemporalLPfilter(obj.demultiplexedTempBuffer(:,:,2), obj.chrominance(:,:,2), 1);
            obj.chrominance(:,:,3) = obj.spatiotemporalLPfilter(obj.demultiplexedTempBuffer(:,:,3), obj.chrominance(:,:,3), 1);
            % normalize by the photoreceptors local density and retrieve the local luminance
            if ~adaptiveFiltering % compute the gradient on the luminance
                if strcmp(obj.samplingMethod, "RETINA_COLOR_RANDOM")
                    % normalize by photoreceptors density
                    Cr = obj.chrominance(:,:,1) .* obj.colorLocalDensity(:,:,1);
                    Cg = obj.chrominance(:,:,2) .* obj.colorLocalDensity(:,:,2);
                    Cb = obj.chrominance(:,:,3) .* obj.colorLocalDensity(:,:,3);
                    obj.luminance = (Cr + Cg + Cb) .* obj.pG;
                else
                    Cr = obj.chrominance(:,:,1);
                    Cg = obj.chrominance(:,:,2);
                    Cb = obj.chrominance(:,:,3);
                    obj.luminance = (Cr .* obj.pR) + (Cg .* obj.pG) + (Cb .* obj.pB);
                end
                obj.chrominance(:,:,1) = Cr - obj.luminance;
                obj.chrominance(:,:,2) = Cg - obj.luminance;
                obj.chrominance(:,:,3) = Cb - obj.luminance;

                % in order to get the color image, each colored map needs to be added the luminance
                % -> to do so, compute:  multiplexedColorFrame - remultiplexed chrominances
                obj.tempMultiplexedFrame = obj.runColorMultiplexing(obj.chrominance, true);
                obj.luminance = multiplexedColorFrame - obj.tempMultiplexedFrame;
                obj.demultiplexedColorFrame(:,:,1) = obj.chrominance(:,:,1) + obj.luminance;
                obj.demultiplexedColorFrame(:,:,2) = obj.chrominance(:,:,2) + obj.luminance;
                obj.demultiplexedColorFrame(:,:,3) = obj.chrominance(:,:,3) + obj.luminance;
            else
                % normalize by photoreceptors density
                Cr = obj.chrominance(:,:,1) .* obj.colorLocalDensity(:,:,1);
                Cg = obj.chrominance(:,:,2) .* obj.colorLocalDensity(:,:,2);
                Cb = obj.chrominance(:,:,3) .* obj.colorLocalDensity(:,:,3);
                obj.luminance = (Cr+Cg+Cb) .* obj.pG;
                temp = multiplexedColorFrame - obj.luminance;
                obj.demultiplexedTempBuffer(obj.colorSampling(:)) = temp(:);
                obj.computeGradient(obj.luminance); % compute the gradient of the luminance
                % adaptively filter the submosaics to get the adaptive densities, here the buffer obj.chrominance is used as a temp buffer
                obj.chrominance(:,:,1) = obj.adaptiveSpatialLPfilter(obj.RGBmosaic(:,:,1));
                obj.chrominance(:,:,2) = obj.adaptiveSpatialLPfilter(obj.RGBmosaic(:,:,2));
                obj.chrominance(:,:,3) = obj.adaptiveSpatialLPfilter(obj.RGBmosaic(:,:,3));
                obj.demultiplexedColorFrame(:,:,1) = obj.adaptiveSpatialLPfilter(obj.demultiplexedTempBuffer(:,:,1));
                obj.demultiplexedColorFrame(:,:,2) = obj.adaptiveSpatialLPfilter(obj.demultiplexedTempBuffer(:,:,2));
                obj.demultiplexedColorFrame(:,:,3) = obj.adaptiveSpatialLPfilter(obj.demultiplexedTempBuffer(:,:,3));
                obj.chrominance(obj.chrominance==0) = .0000000000000001; %avoid divide by zero
                obj.demultiplexedColorFrame = obj.demultiplexedColorFrame ./ obj.chrominance; % more optimal ;o)
                % compute and substract the residual luminance
                residu = obj.pR .* obj.demultiplexedColorFrame(:,:,1) + obj.pG .* obj.demultiplexedColorFrame(:,:,2) + obj.pB .* obj.demultiplexedColorFrame(:,:,3);
                obj.demultiplexedColorFrame(:,:,1) = obj.demultiplexedColorFrame(:,:,1) - residu;
                obj.demultiplexedColorFrame(:,:,2) = obj.demultiplexedColorFrame(:,:,2) - residu;
                obj.demultiplexedColorFrame(:,:,3) = obj.demultiplexedColorFrame(:,:,3) - residu;
                % multiplex the obtained chrominance
                obj.tempMultiplexedFrame = obj.runColorMultiplexing(obj.demultiplexedColorFrame, true);                
                obj.demultiplexedTempBuffer(:) = 0;

                % get the luminance, et and add it to each chrominance
                obj.luminance = multiplexedColorFrame - obj.tempMultiplexedFrame;
                obj.demultiplexedTempBuffer(obj.colorSampling(:)) = obj.demultiplexedColorFrame(obj.colorSampling(:));
                obj.demultiplexedTempBuffer(:,:,1) = obj.spatiotemporalLPfilter(obj.demultiplexedTempBuffer(:,:,1), obj.demultiplexedTempBuffer(:,:,1), 1);
                obj.demultiplexedTempBuffer(:,:,2) = obj.spatiotemporalLPfilter(obj.demultiplexedTempBuffer(:,:,2), obj.demultiplexedTempBuffer(:,:,2), 1);
                obj.demultiplexedTempBuffer(:,:,3) = obj.spatiotemporalLPfilter(obj.demultiplexedTempBuffer(:,:,3), obj.demultiplexedTempBuffer(:,:,3), 1);
                % get the luminance and add it to each chrominance
                obj.demultiplexedColorFrame(:,:,1) = obj.demultiplexedTempBuffer(:,:,1) .* obj.colorLocalDensity(:,:,1) + obj.luminance;
                obj.demultiplexedColorFrame(:,:,2) = obj.demultiplexedTempBuffer(:,:,2) .* obj.colorLocalDensity(:,:,2) + obj.luminance;
                obj.demultiplexedColorFrame(:,:,3) = obj.demultiplexedTempBuffer(:,:,3) .* obj.colorLocalDensity(:,:,3) + obj.luminance;
            end
            
            % eliminate saturated colors by simple clipping values to the input range
            above = obj.demultiplexedColorFrame > 1;
            obj.demultiplexedColorFrame(above) = 1;
            below = obj.demultiplexedColorFrame < 0;
            obj.demultiplexedColorFrame(below) = 0;
            
            if obj.saturateColors
                obj.demultiplexedColorFrame(:,:,1) = obj.demultiplexedColorFrame.normalizeGrayOutputCentredSigmoide(0, obj.colorSaturationValue, obj.demultiplexedColorFrame(:,:,1));
                obj.demultiplexedColorFrame(:,:,2) = obj.demultiplexedColorFrame.normalizeGrayOutputCentredSigmoide(0, obj.colorSaturationValue, obj.demultiplexedColorFrame(:,:,2));
                obj.demultiplexedColorFrame(:,:,3) = obj.demultiplexedColorFrame.normalizeGrayOutputCentredSigmoide(0, obj.colorSaturationValue, obj.demultiplexedColorFrame(:,:,3));
            end
        end

        % activate color saturation as the final step of the color demultiplexing process
        % -> this saturation is a sigmoide function applied to each channel of the demultiplexed image.
        % @param saturateColors - scalar logical, activates color saturation (if true) or deactivates (if false)
        % @param colorSaturationValue - scalar double, the saturation factor
        function [] = setColorSaturation (obj, saturateColors, colorSaturationValue)
            if ~exist('saturateColors', 'var') || isempty(saturateColors)
                saturateColors = true;
            end
            if ~exist('colorSaturationValue', 'var') || isempty(colorSaturationValue)
                colorSaturationValue = 4;
            end
            obj.saturateColors = saturateColors;
            obj.colorSaturationValue = colorSaturationValue;
        end

        % set parameters of the low pass spatio-temporal filter used to retreive the low chrominance
        % @param beta - scalar double, gain of the filter (generally set to zero)
        % @param tau - scalar double, time constant of the filter (unit is frame for video processing), typically 0 when considering static processing, 1 or more if a temporal smoothing effect is required
        % @param k - scalar double, spatial constant of the filter (unit is pixels), typical value is 2.5
        function [] = setChrominanceLPfilterParameters (obj, beta, tau, k)
            obj.setLPfilterParameters(beta, tau, k);
        end

        % apply to the retina color output the Krauskopf transformation which leads to an opponent color system: output colorspace if Acr1cr2 if input of the retina was LMS color space
        % @param result: the input buffer to fill with the transformed colorspace retina output
        % @return true if process ended successfully
        function [result] = applyKrauskopfLMS2Acr1cr2Transform (obj, result)
            assert(all(size(result) == size(obj.demultiplexedColorFrame))); 
            result = obj.applyImageColorSpaceConversion(obj.demultiplexedColorFrame, result, obj.LMStoACr1Cr2); % apply transformation
        end

        % apply to the retina color output the CIE Lab color transformation
        % @param result: the input buffer to fill with the transformed colorspace retina output
        % @return true if process ended successfully
        function [result] = applyLMS2LabTransform (obj, result)
            assert(all(size(result) == size(obj.demultiplexedColorFrame)));          
            result = obj.applyImageColorSpaceConversion(obj.demultiplexedColorFrame, result, obj.LMStoLab); % apply transformation
        end

        % standard normalization function appled to RGB images (of size M*N*3 pixels)
        function [] = normalizeRGBOutput (obj)
            obj.demultiplexedColorFrame = obj.demultiplexedColorFrame.normalizeGrayOutput(obj.demultiplexedColorFrame);
            obj.luminance = obj.luminance.normalizeGrayOutput(obj.luminance);
        end

        % function used to bypass processing and manually set the color output
        % @param demultiplexedImage: the color image (luminance+chrominance) which has to be written in the object buffer
        function [] = setDemultiplexedColorFrame (obj, demultiplexedImage)
            obj.demultiplexedColorFrame = demultiplexedImage;
        end

        %% gets
        
        % @return the multiplexed frame result (use this after function runColorMultiplexing)
        function [retVal] = getMultiplexedFrame (obj)
            retVal = obj.multiplexedFrame;
        end
        % @return the demultiplexed frame result (use this after function runColorDemultiplexing)
        function [retVal] = getDemultiplexedColorFrame (obj)
            retVal = obj.demultiplexedColorFrame;
        end
        % @return the luminance of the processed frame (use this after function runColorDemultiplexing)
        function [retVal] = getLuminance (obj)
            retVal = obj.luminance;
        end
        % @return the chrominance of the processed frame (use this after function runColorDemultiplexing)
        function [retVal] = getChrominance (obj)
            retVal = obj.chrominance;
        end
        % return the color sampling map: a Nrows*Mcolumns image in which each pixel value is the ofsset adress which gives the adress of the sampled pixel on an Nrows*Mcolumns*3 color image ordered by layers: layer1, layer2, layer3
        function [retVal] = getSamplingMap (obj)
            retVal = obj.colorSampling;
        end
    end
    
    methods (Access = protected)
        function [] = initColorSampling (obj)
            % filling the conversion table for multiplexed <=> demultiplexed frame
            % preInit cones probabilities
            obj.pR = 0;
            obj.pB = 0;
            obj.pG = 0;
            if strcmp(obj.samplingMethod, "RETINA_COLOR_RANDOM")
                rng('shuffle');
                colorIndex = randi([0, 23], size(obj.filterOutput, 1), size(obj.filterOutput, 2));
                obj.colorSampling = 1 + int8(colorIndex > 7) + int8(colorIndex > 20);
                obj.pR = sum(int8(colorIndex < 8), 'all');
                obj.pG = (sum(int8(colorIndex < 21), 'all') - obj.pR) / obj.getNBpixels();
                obj.pB = (sum(int8(colorIndex > 20), 'all')) / obj.getNBpixels();
                obj.pR = obj.pR / obj.getNBpixels();
                for r = 1:size(obj.filterOutput, 1)
                    for c = 1:size(obj.filterOutput, 2)
                        obj.colorSampling(r, c) = sub2ind([size(obj.filterOutput, 1), size(obj.filterOutput, 2), 3], r, c, obj.colorSampling(r, c));
                    end
                end
                %disp(['Color channels proportions: pR, pG, pB= ',obj.pR,', ',obj.pG,', ',obj.pB,', '])
            elseif strcmp(obj.samplingMethod, "RETINA_COLOR_DIAGONAL")
                i = 0;
                for r = 1:size(obj.filterOutput, 1)
                    for c = 1:size(obj.filterOutput, 2)
                        obj.colorSampling(r, c) = 1 + rem(rem(i, 3) + c, 3);
                        i = i+1;
                       obj.colorSampling(r, c) = sub2ind([size(obj.filterOutput, 1), size(obj.filterOutput, 2), 3], r, c, obj.colorSampling(r, c));
                    end
                end
                obj.pR = 1 / 3;
                obj.pB = 1 / 3;
                obj.pG = 1 / 3;
            elseif strcmp(obj.samplingMethod, "RETINA_COLOR_BAYER") % default sets bayer sampling
                for r = 1:size(obj.filterOutput, 1)
                    for c = 1:size(obj.filterOutput, 2)
                        obj.colorSampling(r, c) = 1 + rem(r+1, 2)+rem(c+1, 2);
                        obj.colorSampling(r, c) = sub2ind([size(obj.filterOutput, 1), size(obj.filterOutput, 2), 3], r, c, obj.colorSampling(r, c));
                    end
                end
                obj.pR = 0.25;
                obj.pB = 0.25;
                obj.pG = 0.5;
            else
                error('no or wrong color sampling method');
            end
           
            % filling the mosaic buffer
            obj.RGBmosaic(:) = 0;
            obj.RGBmosaic(obj.colorSampling(:)) = 1;

            % computing photoreceptors local density
            obj.colorLocalDensity(:,:, 1) = obj.spatiotemporalLPfilter(obj.RGBmosaic(:,:,1), obj.colorLocalDensity(:,:,1), 1);
            obj.colorLocalDensity(:,:, 2) = obj.spatiotemporalLPfilter(obj.RGBmosaic(:,:,2), obj.colorLocalDensity(:,:,2), 1);
            obj.colorLocalDensity(:,:, 3) = obj.spatiotemporalLPfilter(obj.RGBmosaic(:,:,3), obj.colorLocalDensity(:,:,3), 1);
            
            obj.colorLocalDensity = 1 ./ obj.colorLocalDensity;

            obj.objectInit = true;
        end


        function [image] = interpolateImageDemultiplexedImage (obj, image)
            if strcmp(obj.samplingMethod, "RETINA_COLOR_RANDOM")
                return; % no need to interpolate
            elseif strcmp(obj.samplingMethod, "RETINA_COLOR_DIAGONAL") %single channel image 111
                for c = 2:size(image, 2)-1
                     image(:, c) = image(:, c-1) + image(:, c) + image(:, c+1);
                end
                image = image ./3;
                for r = 2:size(image, 1) - 1
                    image(r, :) = image(r-1, :) + image(r, :) + image(r+1, :);
                end
                image = image ./3;
            elseif strcmp(obj.samplingMethod, "RETINA_COLOR_BAYER") % default sets bayer sampling
                for r = 1:2:size(image, 1)-1
                    for c = 2:2:size(image, 2) - 1
                        image(r, c, 1) = (image(r, c-1)+image(r, c+1)) / 2;
                        image(r+1, c+1, 3) = (image(r+1, c)+image(r+1, c+2)) / 2;
                    end
                end
                for r = 2:2:size(image, 1) - 1
                    for c = 1:size(image, 2)
                        image(r, c, 1) = (inputOutputBuffer(r-1, c)+image(r+1, c)) / 2;
                        image(r+1, c+1, 3) = (inputOutputBuffer(r, c+1)+image(r+2, c+1)) / 2;
                    end
                end
                for r = 2:size(image, 1) - 1
                    for c = 1:2:size(image, 2)
                        c1 = c+rem(r+1, 2);
                        image(r, c1, 2) = (image(r, c1-1)+image(r, c1+1)+image(r-1, c1)+image(r+1, c1)) * 0.25;
                    end
                end
            else
                error('no or wrong color sampling method');
            end
        end


        %% //////////////////////////////////////////////////////////
        %% //        ADAPTIVE BASIC RETINA FILTER
        %% //////////////////////////////////////////////////////////
        
        % run LP filter for a new frame input and save result at a specific output adress
        function [image] = adaptiveSpatialLPfilter (obj, image)
            obj.gain = (1 - 0.57) * (1 - 0.57) * (1 - 0.06) * (1 - 0.06);

            % launch the series of 1D directional filters in order to compute the 2D low pass filter
            % -> horizontal filters work with the first layer of imageGradient
            
            % horizontal causal filter which adds the input inside... replaces the parent _horizontalCausalFilter_Irregular_addInput by avoiding a product for each pixel
            for c = 2:size(obj.filterOutput, 2)
                image(:, c) = image(:, c-1) .* obj.imageGradient(:, c, 1) + image(:, c);
            end
            
            image = obj.horizontalAnticausalFilter_Irregular(image, obj.imageGradient(:,:,1));
            
            % -> horizontal filters work with the second layer of imageGradient
            image = obj.verticalCausalFilter_Irregular(image, obj.imageGradient(:,:,2));
            
            % vertical anticausal filter that multiplies the output by obj.gain... replaces the parent _verticalAnticausalFilter_multGain by avoiding a product for each pixel and taking into account the second layer of the obj.imageGradient buffer
            for r = size(obj.filterOutput, 1)-1:-1:1
                image(r, :) = image(r+1, :) .* obj.imageGradient(r, :, 2) + image(r, :);
            end
            image = image .* obj.gain;
        end

        function [] = computeGradient (obj, luminance)
            horizontalGradient = obj.imageGradient;
            verticalGradient = obj.imageGradient;
            for r = 3:size(obj.filterOutput, 1)-2
                verticalGradient(r, :) = (0.5 .* abs(luminance(r+1,:) - luminance(r-1,:))) + (0.25 .* (abs(luminance(r,:) - luminance(r-2,:)) + abs(luminance(r+2,:) - luminance(r,:))));
            end
            for c = 3:size(obj.filterOutput, 2)-2
                horizontalGradient(:, c) = (0.5 .* abs(luminance(:,c+1) - luminance(:,c-1))) + (0.25 .* (abs(luminance(:,c) - luminance(:,c-2)) + abs(luminance(:,c+2) - luminance(:,c))));
            end
            % compare local gradient means and fill the appropriate filtering coefficient value that will be used in adaptative filters
            obj.imageGradient(:, :, 1) = 0.06 + (double(horizontalGradient(:, :) < verticalGradient(:, :))*0.51);
            obj.imageGradient(:, :, 2) = 0.06 + (double(horizontalGradient(:, :) >= verticalGradient(:, :))*0.51);
        end

        % template function able to perform a custom color space transformation
        function [outputFrameBuffer] = applyImageColorSpaceConversion (obj, inputFrameBuffer, outputFrameBuffer, transformTable)
            % two step methods in order to allow inputFrame and outputFrame to be the same
            thirdRows = size(inputFrameBuffer, 1)/3;
            for r = 1:thirdRows
                for c = 1:size(inputFrameBuffer, 2)
                    % first step, compute each new values
                    layer1 = inputFrameBuffer(r, c) * transformTable(1, 1) + inputFrameBuffer(r+thirdRows, c) * transformTable(1, 2) + inputFrameBuffer(r+2*thirdRows, c) * transformTable(1, 3);
                    layer2 = inputFrameBuffer(r, c) * transformTable(2, 1) + inputFrameBuffer(r+thirdRows, c) * transformTable(2, 2) + inputFrameBuffer(r+2*thirdRows, c) * transformTable(2, 3);
                    layer3 = inputFrameBuffer(r, c) * transformTable(3, 1) + inputFrameBuffer(r+thirdRows, c) * transformTable(3, 2) + inputFrameBuffer(r+2*thirdRows, c) * transformTable(3, 3);
                    % second, affect the output
                    outputFrameBuffer(r, c)          = layer1;
                    outputFrameBuffer(r+thirdRows, c) = layer2;
                    outputFrameBuffer(r+thirdRows, c) = layer3;
                end
            end
        end
    end
end
