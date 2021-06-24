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
classdef BasicRetinaFilter < handle
    properties (SetAccess = protected)
        %% data buffers
        filterOutput % primary buffer (contains processing outputs)
        % ----------------
        %% PARAMETERS
        nRows(1,1)
        nCols(1,1)

        % parameters buffers
        filteringCoefficientsTable
        progressiveSpatialConstant % pointer to a local table containing local spatial constant (allocated with the object)
        progressiveGain % pointer to a local table containing local spatial constant (allocated with the object)
        
        % local adaptation filtering parameters
        v0(1,1) % value used for local luminance adaptation function
        localLuminanceFactor(1,1)
        localLuminanceAddon(1,1)

        % protected data related to standard low pass filters parameters
        a(1,1)
        tau(1,1)
        gain(1,1)
    end
    
    
    methods
        % constructor of the base bio-inspired toolbox, parameters are only linked to image input size and number of filtering capabilities of the object
        % @param nRows - scalar double, number of rows of the input image
        % @param nCols - scalar double, number of columns of the input image
        % @param parametersListSize - scalar double, specifies the number of parameters set (each parameters set represents a specific low pass spatio-temporal filter)
        % @param useProgressiveFilter - scalar logical, specifies if the filter has irreguar (progressive) filtering capabilities (this can be activated later using setProgressiveFilterConstants_xxx methods)
        function [obj] = BasicRetinaFilter (nRows, nCols, parametersListSize, useProgressiveFilter)
            if (nargin > 0)
                obj.filterOutput = zeros(nRows, nCols);
            
                obj.filteringCoefficientsTable = zeros(parametersListSize, 3); % alpha, gain, tau in that order
            
                obj.progressiveSpatialConstant = zeros(obj.nRows, obj.nCols); % pointer to a local table containing local spatial constant (allocated with the object)
                obj.progressiveGain = 0;
            
                obj.nRows = nRows;
                obj.nCols = nCols;
            
                if useProgressiveFilter
                    obj.progressiveSpatialConstant = zeros(obj.nRows, obj.nCols);
                    obj.progressiveGain            = zeros(obj.nRows, obj.nCols);
                end

                obj.clearAllBuffers();
            end
        end


        % function which clears the output buffer of the object
        function [] = clearAllBuffers (obj)
            obj.filterOutput(:) = 0;
        end
        
        % ///////////////////////////////////////////////////////////////////////
        %% Spatio temporal Low Pass filter functions

        % low pass filter call and run (models the homogeneous cells network at the retina level, for example horizontal cells or photoreceptors)
        % @param image: the input image to be processed
        % @param filterIndex - scalar double, the offset which specifies the parameter set that should be used for the filtering
        % run LP filter for a new frame input and save result at a specific output adress
        function [image] = runFilter_LPfilter (obj, input, output, filterIndex)
            image = obj.spatiotemporalLPfilter(input, output, filterIndex);
        end

        % low pass filter call and run (models the homogeneous cells network at the retina level, for example horizontal cells or photoreceptors)
        % @param image: the input image to be processed and on which the result is rewritten
        % @param filterIndex - scalar double, the offset which specifies the parameter set that should be used for the filtering
        % run LP filter on the input data and rewrite it
        function [image] = runFilter_LPfilter_Autonomous (obj, image, filterIndex)
            obj.a    = obj.filteringCoefficientsTable(filterIndex,1);
            obj.gain = obj.filteringCoefficientsTable(filterIndex,2);
            obj.tau  = obj.filteringCoefficientsTable(filterIndex,3);

            % launch the series of 1D directional filters in order to compute the 2D low pass filter
            image = obj.horizontalCausalFilter(image);
            image = obj.horizontalAnticausalFilter(image);
            image = obj.verticalCausalFilter(image);
            image = obj.verticalAnticausalFilter_multGain(image);
        end
        
        % ///////////////////////////////////////////////////////////////////////
        %% Local luminance adaptation functions

        % local luminance adaptation call and run (contrast enhancement property of the photoreceptors)
        % @param inputOutputFrame: the input image to be processed
        % @param localLuminance: an image which represents the local luminance of the inputFrame parameter, in general, its low pass spatial filtering
        % @return the processed image
        % run local adaptation filter and save result in filterOutput
        function [image] = runFilter_LocalAdaptation (obj, image, localLuminance)
            image = obj.localLuminanceAdaptation(image, localLuminance, false);
        end
        
        % local luminance adaptation call and run (contrast enhancement property of the photoreceptors)
        % @param image: the input image to be processed
        % @return the processed image
        % run local adaptation filter and save result in _filterOutput with autonomous low pass filtering before adaptation
        function [image] = runFilter_LocalAdaptation_autonomous (obj, image)
            temp = obj.spatiotemporalLPfilter(image);
            image = obj.localLuminanceAdaptation(image, temp, false);
        end

        % first order spatio-temporal low pass filter setup function
        % @param beta - scalar double, gain of the filter (generally set to zero)
        % @param tau - scalar double, time constant of the filter (unit is frame for video processing)
        % @param desired_k - scalar double, spatial constant of the filter (unit is pixels)
        % @param filterIndex - scalar double, the index which specifies the parameter set that should be used for the filtering
        % Change coefficients table
        function [] = setLPfilterParameters (obj, beta, tau, desired_k, filterIndex)
            assert(desired_k > 0, 'spatial constant of the low pass filter must be > 0');
            
            alpha = desired_k * desired_k;
            beta = beta + tau;
            mu = 0.8;

            temp = (1+beta) / (2*mu*alpha);
            obj.a = 1 + temp - sqrt((1+temp)*(1+temp) - 1);
            obj.filteringCoefficientsTable(filterIndex, 1) = obj.a;
            obj.filteringCoefficientsTable(filterIndex,2) = (1-obj.a).^4 / (1+beta);
            obj.filteringCoefficientsTable(filterIndex,3) = tau;
        end

        % first order spatio-temporal low pass filter setup function
        % @param beta - scalar double, gain of the filter (generally set to zero)
        % @param tau - scalar double, time constant of the filter (unit is frame for video processing)
        % @param alpha0 - scalar double, spatial constant of the filter (unit is pixels) on the border of the image
        % @param filterIndex - scalar double, the index which specifies the parameter set that should be used for the filtering
        function [] = setProgressiveFilterConstants_CentredAccuracy (obj, beta, tau, alpha0, filterIndex)
            assert(alpha0 > 0, 'spatial filtering coefficient must be > 0');
          
            % check if dedicated buffers are already allocated, if not create them
            if isempty(obj.progressiveSpatialConstant)
                obj.progressiveSpatialConstant = zeros(obj.nRows, obj.nCols);
                obj.progressiveGain            = zeros(obj.nRows, obj.nCols);
            end

            alpha = 0.8;
            beta = beta + tau;
            mu = 0.8;
            
            temp = (1+beta) / (2*mu*alpha);
            obj.a = 1 + temp - sqrt((1+temp) * (1+temp) - 1);
            obj.filteringCoefficientsTable(filterIndex,1) = obj.a;
            obj.filteringCoefficientsTable(filterIndex,2) = (1-obj.a).^4 / (1+beta);
            obj.filteringCoefficientsTable(filterIndex,3) = tau;

            halfNBrows = obj.nRows / 2;
            halfNBcols = obj.nCols / 2;
            commonFactor = alpha0 / sqrt(halfNBcols^2 + halfNBrows^2 + 1);
            for c = 1:halfNBcols
                for r = 1:halfNBrows
                    localSpatialConstant = min(1, commonFactor * sqrt(c^2 + r^2));

                    obj.progressiveSpatialConstant(halfNBrows+r, halfNBcols+c) = localSpatialConstant;
                    obj.progressiveSpatialConstant(halfNBrows+r, halfNBcols+1-c) = localSpatialConstant;
                    obj.progressiveSpatialConstant(halfNBrows+1-r, halfNBcols+c) = localSpatialConstant;
                    obj.progressiveSpatialConstant(halfNBrows+1-r, halfNBcols+1-c) = localSpatialConstant;

                    localGain = (1-localSpatialConstant).^4 / (1+beta);
                    obj.progressiveGain(halfNBrows+r, halfNBcols+c) = localGain;
                    obj.progressiveGain(halfNBrows+r, halfNBcols+1-c) = localGain;
                    obj.progressiveGain(halfNBrows+1-r, halfNBcols+c) = localGain;
                    obj.progressiveGain(halfNBrows+1-r, halfNBcols+1-c) = localGain;
                end
            end
        end

        % first order spatio-temporal low pass filter setup function
        % @param beta - scalar double, gain of the filter (generally set to zero)
        % @param tau - scalar double, time constant of the filter (unit is frame for video processing)
        % @param alpha0 - scalar double, spatial constant of the filter (unit is pixels) on the border of the image
        % @param accuracyMap an image (matrix of doubles) which values range is between 0 and 1, where 0 means apply no filtering and 1 means apply the filtering as specified in the parameters set, intermediate values allow to smooth variations of the filtering strength
        % @param filterIndex - scalar double, the index which specifies the parameter set that should be used for the filtering
        function [] = setProgressiveFilterConstants_CustomAccuracy (obj, beta, tau, k, accuracyMap, filterIndex)
            assert(k > 0, 'spatial filtering coefficient k must be > 0');
            assert(size(accuracyMap, 1) == obj.nRows && size(accuracyMap, 2) == obj.nCols);

            % check if dedicated buffers are already allocated, if not create them
            if isempty(obj.progressiveSpatialConstant)
                obj.progressiveSpatialConstant = zeros(obj.nRows, obj.nCols);
                obj.progressiveGain            = zeros(obj.nRows, obj.nCols);
            end
            
            alpha = k * k;
            beta = beta + tau;
            mu = 0.8;
            
            temp = (1 + beta) / (2 * mu * alpha);
            obj.a = 1 + temp - sqrt((1+temp)*(1+temp) - 1);
            obj.filteringCoefficientsTable(filterIndex,1) = obj.a;
            obj.filteringCoefficientsTable(filterIndex,2) = (1-obj.a).^4 / (1+beta);
            obj.filteringCoefficientsTable(filterIndex,3) = tau;
            
            localSpatialConstant = min(1, obj.a .* accuracyMap); % compute local spatial constant
            obj.progressiveSpatialConstant = localSpatialConstant;
            
            obj.progressiveGain = (1-localSpatialConstant).^4 ./ (1+beta); % compute local gain
        end

        % local luminance adaptation setup, this function should be applied for normal local adaptation (not for tone mapping operation)
        % @param v0 - scalar double, compression effect for the local luminance adaptation processing, set a value between 0.6 and 0.9 for best results, a high value yields to a high compression effect
        function [] = setV0CompressionParameter3 (obj, v0)
            obj.localLuminanceFactor = v0;
            obj.localLuminanceAddon = (1-v0);
        end
        % update local luminance adaptation setup, initial maxInputValue is kept. This function should be applied for normal local adaptation (not for tone mapping operation)
        % @param v0 - scalar double, compression effect for the local luminance adaptation processing, set a value between 0.6 and 0.9 for best results, a high value yields to a high compression effect
        function [] = setV0CompressionParameter2 (obj, v0)
            obj.setV0CompressionParameter3(v0);
        end
        % local luminance adaptation setup, this function should be applied for normal local adaptation (not for tone mapping operation)
        % @param v0 - scalar double compression effect for the local luminance adaptation processing, set a value between 0.6 and 0.9 for best results, a high value yields to a high compression effect
        function [] = setV0CompressionParameter1 (obj, v0)
            obj.v0 = v0 * 1;
            obj.localLuminanceFactor = v0;
            obj.localLuminanceAddon = 1 * (1-v0);
        end
        % local luminance adaptation setup, this function should be applied for local adaptation applied to tone mapping operation
        % @param v0 - scalar double, compression effect for the local luminance adaptation processing, set a value between 0.6 and 0.9 for best results, a high value yields to a high compression effect
        % @param meanLuminance - scalar double, the a priori meann luminance of the input data
        function [] = setV0CompressionParameterToneMapping (obj, v0, meanLuminance)
            if ~exist('meanLuminance', 'var') || isempty(meanLuminance)
                meanLuminance = 0;
            end
            obj.v0 = v0 * 1;
            obj.localLuminanceFactor = 1;
            obj.localLuminanceAddon = meanLuminance * v0;
        end

        % update compression parameters while keeping v0 parameter value
        % @param meanLuminance - scalar double, the input frame mean luminance
        function [] = updateCompressionParameter (obj, meanLuminance)
            obj.localLuminanceFactor = 1;
            obj.localLuminanceAddon = meanLuminance * obj.v0;
        end
        
        
        %% gets

        % @return the v0 compression parameter used to compute the local adaptation
        function [retVal] = getV0CompressionParameter (obj)
            retVal = obj.v0;
        end
        % @return number of rows of the filter
        function [retVal] = getNBrows (obj)
            retVal = obj.nRows;
        end
        % @return number of columns of the filter
        function [retVal] = getNBcolumns (obj)
            retVal = obj.nCols;
        end  
        % @return number of pixels of the filter
        function [retVal] = getNBpixels(obj)
            retVal = obj.nCols*obj.nRows;
        end
    end
    
    
    methods (Access = protected)
        % ----------------
        %% FILTER METHODS

        %% Basic low pass spatiotemporal low pass filter used by each retina filters

        % run LP filter for a new frame input and save result at a specific output adress
        function [image] = spatiotemporalLPfilter (obj, input, output, filterIndex)
            obj.a    = obj.filteringCoefficientsTable(filterIndex,1);
            obj.gain = obj.filteringCoefficientsTable(filterIndex,2);
            obj.tau  = obj.filteringCoefficientsTable(filterIndex,3);

            % launch the series of 1D directional filters in order to compute the 2D low pass filter
            image = obj.horizontalCausalFilter_addInput(input, output);
            image = obj.horizontalAnticausalFilter(image);
            image = obj.verticalCausalFilter(image);
            image = obj.verticalAnticausalFilter_multGain(image);
        end

        % run SQUARING LP filter for a new frame input and save result at a specific output adress
        function [inOutFrame, retVal] = squaringSpatiotemporalLPfilter (obj, inputFrame, outputFrame, filterIndex)
            obj.a    = obj.filteringCoefficientsTable(filterIndex,1);
            obj.gain = obj.filteringCoefficientsTable(filterIndex,2);
            obj.tau  = obj.filteringCoefficientsTable(filterIndex,3);

            % launch the series of 1D directional filters in order to compute the 2D low pass filter
            outputFrame = obj.squaringHorizontalCausalFilter(inputFrame, outputFrame);
            outputFrame = obj.horizontalAnticausalFilter(outputFrame);
            outputFrame = obj.verticalCausalFilter(outputFrame);
            [inOutFrame,retVal] = obj.verticalAnticausalFilter(outputFrame);
        end

        % local luminance adaptation of the input in regard of localLuminance buffer
        function [inputFrame] = localLuminanceAdaptation (obj, inputFrame, localLuminance, updateLuminanceMean)
            if ~exist('updateLuminanceMean', 'var') || isempty(updateLuminanceMean)
                updateLuminanceMean = true;
            end
            if updateLuminanceMean
                obj.updateCompressionParameter(mean(inputFrame(:)));
            end
            X0 = localLuminance .* obj.localLuminanceFactor + obj.localLuminanceAddon;
            inputFrame = cast(inputFrame, 'double');
            % the following line can lead to a divide by zero ! A small offset is added, take care if the offset is too large in case of High Dynamic Range images which can use very small values...
            inputFrame = ((X0 + 1) .* inputFrame) ./ (inputFrame + X0 + 0.0000000000000000001);            
        end


        % /////////////////////////////////////////////////
        %% standard version of the 1D low pass filters

        % horizontal causal filter which adds the input inside
        function [image] = horizontalCausalFilter (obj, image)
            for c = 2:size(image, 2)
                image(:, c) = image(:, c-1) .* obj.a + image(:, c);
            end
        end
             
        % horizontal causal filter which adds the input inside
        function [outputFrame] = horizontalCausalFilter_addInput (obj, inputFrame, outputFrame)
            outputFrame = inputFrame + obj.tau .* outputFrame;
            for c = 2:size(inputFrame, 2)
                outputFrame(:, c) = outputFrame(:, c-1) .* obj.a + outputFrame(:, c);
            end
        end


        % horizontal anticausal filter  (basic way, no add on)
        function [image] = horizontalAnticausalFilter (obj, image)
            for c = size(image, 2)-1:-1:1
                image(:,c) = image(:,c+1) * obj.a + image(:, c);
            end
        end


        function [image] = verticalCausalFilter (obj, image)
            for r = 2:size(image, 1)
                image(r, :) = image(r, :) + image(r-1, :) .* obj.a;
            end
        end

        
        function [image,retVal] = verticalAnticausalFilter (obj, image)
            for r = size(image, 1)-1:-1:1
                image(r, :) = image(r+1, :) * obj.a + image(r, :);
            end
            retVal = mean(image);
        end

         function [image] = verticalAnticausalFilter_multGain (obj, image)   
            for r = size(image, 1)-1:-1:1
                 image(r,:) = image(r,:) + image(r+1,:) .* obj.a;
            end
            image = obj.gain .* image;
         end

        
        % /////////////////////////////////////////
        %% specific modifications of 1D filters

        % -> squaring horizontal causal filter
        function [output] = squaringHorizontalCausalFilter (obj, input, output)
            output = input .* input + obj.tau .* output;
            for c = 2:size(input, 2)
                output(:, c) = output(:, c-1) .* obj.a + output(:, c);
            end
        end

        % ////////////////////////////////////////////////////
        %% run LP filter for a new frame input and save result at a specific output adress
        % -> USE IRREGULAR SPATIAL CONSTANT
        
        %irregular filter computed from buffer, writes results to outputFrame
        function [outputFrame] = spatiotemporalLPfilter_Irregular (obj, inputFrame, outputFrame, filterIndex)
            assert(~isempty(obj.progressiveGain), 'can only perform filtering if progressive filter is set up');
            
            obj.tau = obj.filteringCoefficientsTable(filterIndex,3);
            
            % launch the series of 1D directional filters in order to compute the 2D low pass filter
            outputFrame = obj.horizontalCausalFilter_Irregular_addInput(inputFrame, outputFrame);
            outputFrame = obj.horizontalAnticausalFilter_Irregular(outputFrame, obj.progressiveSpatialConstant);
            outputFrame = obj.verticalCausalFilter_Irregular(outputFrame, obj.progressiveSpatialConstant);
            outputFrame = obj.verticalAnticausalFilter_Irregular_multGain(outputFrame);
        end

        %horizontal causal filter with add input
        function [outputFrame] = horizontalCausalFilter_Irregular_addInput (obj, inputFrame, outputFrame)
            outputFrame = inputFrame + obj.tau .* outputFrame;
            for c = 2:size(inputFrame, 2)
                outputFrame(:, c) = outputFrame(:, c-1) .* obj.progressiveSpatialConstant(:, c) + outputFrame(:, c);
            end
  
        end

        % horizontal anticausal filter  (basic way, no add on)
        function [image] = horizontalAnticausalFilter_Irregular (obj, image, spatialConstantBuffer)
            for c = size(image, 2)-1:-1:1
                image(:, c) = image(:, c+1) .* spatialConstantBuffer(:, c) + image(:, c);
            end
        end
 
        % vertical anticausal filter
        function [image] = verticalCausalFilter_Irregular (obj, image, spatialConstantBuffer)
            for r = 2:size(image, 1)
                image(r, :) = image(r-1, :) .* spatialConstantBuffer(r, :) + image(r, :);
            end
        end

        % vertical anticausal filter which multiplies the output by obj.gain
        function [image] = verticalAnticausalFilter_Irregular_multGain (obj, image)
            for r = size(image, 1)-1:-1:1
                image(r, :) = image(r+1, :) .* obj.progressiveSpatialConstant(r, :) + image(r, :);
            end
            image = image .* (obj.progressiveGain);
        end
        
        % force filter output to be normalized around 0 and rescaled with a sigmoide effect (extreme values saturation)
        function [image] = normalizeGrayOutputCentredSigmoide (obj, meanValue, sensitivity, image)
            if ~exist('meanValue', 'var') || isempty(meanValue)
                meanValue = 0;
            end
            if ~exist('sensitivity', 'var') || isempty(sensitivity)
                sensitivity = 2;
            end
            assert(sensitivity ~= 1, '2nd parameter (sensitivity) must not equal 1'); %divide by 0 issue
            X0 = 1/(sensitivity-1.0);
            image = meanValue+(meanValue+X0).*(image-meanValue)./(abs(image-meanValue)+X0);
        end
        
        % image normalization function
        function [image] = normalizeGrayOutput (obj, image)
            maxValue = max(image(:));
            minValue = min(image(:));
            factor = 1 / (maxValue - minValue);
            offset = -minValue * factor;

            image = image .* factor + offset;
        end
    end
end
