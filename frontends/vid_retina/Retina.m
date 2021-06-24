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
classdef Retina < handle
    properties (SetAccess = private)
        retinaParams(1,1) struct = struct('OPLandIplParvo', struct(), 'IplMagno', struct()) % structure of parameters

        retinaFilter(1,1);
    end
        
    methods
        % Complete Retina filter constructor which allows all basic structural parameters definition
        % @param inputSize : the input frame size
        % @param isColor - scalar logical, the chosen processing mode : with or without color processing
        % @param colorSamplingMethod - scalar int specifies which kind of color sampling will be used
        % @param useRetinaLogSampling - scalar logical, activate retina log sampling, if true, the 2 following parameters can be used
        % @param reductionFactor - scalar double, only usefull if param useRetinaLogSampling=true, specifies the reduction factor of the output frame (as the center (fovea) is high resolution and corners can be underscaled, then a reduction of the output is allowed without precision leak
        % @param samplingStrength - scalar double, only usefull if param useRetinaLogSampling=true, specifies the strength of the log scale that is applied
        function [obj] = Retina (nRowsIn, nColsIn, isColor, colorSamplingMethod, useRetinaLogSampling, reductionFactor, samplingStrength)
            assert(nRowsIn * nColsIn > 0, 'Bad retina size setup : size height and with must be > 0');
            if ~exist('colorSamplingMethod', 'var') || isempty(colorSamplingMethod)
                colorSamplingMethod = "RETINA_COLOR_BAYER"; % default
            end
            if ~exist('useRetinaLogSampling', 'var') || isempty(useRetinaLogSampling)
                useRetinaLogSampling = false; % default
            end
            if ~exist('reductionFactor', 'var') || isempty(reductionFactor)
                reductionFactor = 1; % default
            end
            if ~exist('samplingStrength', 'var') || isempty(samplingStrength)
                samplingStrength = 10; % default
            end
            
            % allocate the retina model
            obj.retinaFilter = RetinaFilter(nRowsIn, nColsIn, useRetinaLogSampling, reductionFactor, samplingStrength, colorSamplingMethod, isColor);

            % apply default setup
            obj.setupOPLandIPLParvoChannel(isColor, true, 0.7, 0.5, 0.53, 0, 1, 7, 0.7);
            obj.setupIPLMagnoChannel(true, 0, 0, 7, 1.2, .95, 0, 7);

            obj.retinaFilter.clearAllBuffers();
        end

        % setup the OPL and IPL parvo channels (see biologocal model)
        % OPL is referred as Outer Plexiform Layer of the retina, it allows the spatio-temporal filtering which withens the spectrum and reduces spatio-temporal noise while attenuating global luminance (low frequency energy)
        % IPL parvo is the OPL next processing stage, it refers to Inner Plexiform layer of the retina, it allows high contours sensitivity in foveal vision.
        % for more informations, please have a look at the paper Benoit A., Caplier A., Durette B., Herault, J., "USING HUMAN VISUAL SYSTEM MODELING FOR BIO-INSPIRED LOW LEVEL IMAGE PROCESSING", Elsevier, Computer Vision and Image Understanding 114 (2010), pp. 758-773, DOI: http://dx.doi.org/10.1016/j.cviu.2010.01.011
        % @param colorMode - scalar logical, if true color is processed, if false then gray level image  processing 
        % @param normaliseOutput - scalar logical, if true output is rescaled between min and max values, if false output is not rescaled
        % @param photoreceptorLocalAdaptationSensitivity - scalar double, the photoreceptors sensitivity range is 0-1 (more log compression effect when value increases)
        % @param photoreceptorTemporalConstant - scalar double, the time constant of the first order low pass filter of the photoreceptors, use it to cut high temporal frequencies (noise or fast motion), unit is frames, typical value is 1 frame
        % @param photoreceptorSpatialConstant - scalar double, the spatial constant of the first order low pass filter of the photoreceptors, use it to cut high spatial frequencies (noise or thick contours), unit is pixels, typical value is 1 pixel
        % @param horizontalCellGain - scalar double, gain of the horizontal cells network, if 0, then the mean value of the output is zero, if the parameter is near 1, then, the luminance is not filtered and is still reachable at the output, typicall value is 0
        % @param HcellTemporalConstant - scalar double, the time constant of the first order low pass filter of the horizontal cells, use it to cut low temporal frequencies (local luminance variations), unit is frames, typical value is 1 frame, as the photoreceptors
        % @param HcellSpatialConstant - scalar double, the spatial constant of the first order low pass filter of the horizontal cells, use it to cut low spatial frequencies (local luminance), unit is pixels, typical value is 5 pixel, this value is also used for local contrast computing when computing the local contrast adaptation at the ganglion cells level (Inner Plexiform Layer parvocellular channel model)
        % @param ganglionCellSensitivity - scalar double, the compression strengh of the ganglion cells local adaptation output, set a value between 160 and 250 for best results, a high value increases more the low value sensitivity... and the output saturates faster, recommended value: 230
        function [] = setupOPLandIPLParvoChannel (obj, isColor, normaliseOutput, photoreceptorLocalAdaptationSensitivity, photoreceptorTemporalConstant, photoreceptorSpatialConstant, horizontalCellGain, HcellTemporalConstant, HcellSpatialConstant, ganglionCellSensitivity)
            % retina core parameters setup
            obj.retinaFilter.setPhotoreceptorsLocalAdaptationSensitivity(photoreceptorLocalAdaptationSensitivity);
            obj.retinaFilter.setOPLandParvoParameters(0, photoreceptorTemporalConstant, photoreceptorSpatialConstant, horizontalCellGain, HcellTemporalConstant, HcellSpatialConstant, ganglionCellSensitivity);
            obj.retinaFilter.setParvoGanglionCellsLocalAdaptationSensitivity(ganglionCellSensitivity);
            obj.retinaFilter.activateNormalizeParvoOutput(normaliseOutput);

            % update parameters struture
            obj.retinaParams.OPLandIplParvo.colorMode = isColor;
            obj.retinaParams.OPLandIplParvo.normaliseOutput = normaliseOutput;
            obj.retinaParams.OPLandIplParvo.photoreceptorsLocalAdaptationSensitivity = photoreceptorLocalAdaptationSensitivity;
            obj.retinaParams.OPLandIplParvo.photoreceptorsTemporalConstant = photoreceptorTemporalConstant;
            obj.retinaParams.OPLandIplParvo.photoreceptorsSpatialConstant = photoreceptorSpatialConstant;
            obj.retinaParams.OPLandIplParvo.horizontalCellsGain = horizontalCellGain;
            obj.retinaParams.OPLandIplParvo.hcellsTemporalConstant = HcellTemporalConstant;
            obj.retinaParams.OPLandIplParvo.hcellsSpatialConstant = HcellSpatialConstant;
            obj.retinaParams.OPLandIplParvo.ganglionCellsSensitivity = ganglionCellSensitivity;
        end
        
        % set parameters values for the Inner Plexiform Layer (IPL) magnocellular channel
        % this channel processes signals outpint from OPL processing stage in peripheral vision, it allows motion information enhancement. It is decorrelated from the details channel. See reference paper for more details.
        % @param normaliseOutput - scalar logical, specifies if (true) output is rescaled between 0 and 255 of not (false)
        % @param parasolCell_beta - scalar double, the low pass filter gain used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), typical value is 0
        % @param parasolCell_tau - scalar double, the low pass filter time constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is frame, typical value is 0 (immediate response)
        % @param parasolCell_k - scalar double, the low pass filter spatial constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is pixels, typical value is 5
        % @param amacrinCellTemporalCutFrequency - scalar double, the time constant of the first order high pass fiter of the magnocellular way (motion information channel), unit is frames, tipicall value is 5
        % @param V0CompressionParameter - scalar double, the compression strengh of the ganglion cells local adaptation output, set a value between 160 and 250 for best results, a high value increases more the low value sensitivity... and the output saturates faster, recommended value: 200
        % @param localAdaptintegration_tau - scalar double, specifies the temporal constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation
        % @param localAdaptintegration_k - scalar double, specifies the spatial constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation
        function [] = setupIPLMagnoChannel (obj, normaliseOutput, parasolCell_beta, parasolCell_tau, parasolCell_k, amacrinCellTemporalCutFrequency, V0CompressionParameter, localAdaptintegration_tau, localAdaptintegration_k)
            obj.retinaFilter.setMagnoCoefficientsTable(parasolCell_beta, parasolCell_tau, parasolCell_k, amacrinCellTemporalCutFrequency, V0CompressionParameter, localAdaptintegration_tau, localAdaptintegration_k);
            obj.retinaFilter.activateNormalizeMagnoOutput(normaliseOutput);
            % update parameters struture
            obj.retinaParams.IplMagno.normaliseOutput = normaliseOutput;
            obj.retinaParams.IplMagno.parasolCells_beta = parasolCell_beta;
            obj.retinaParams.IplMagno.parasolCells_tau = parasolCell_tau;
            obj.retinaParams.IplMagno.parasolCells_k = parasolCell_k*10;
            obj.retinaParams.IplMagno.amacrinCellsTemporalCutFrequency = amacrinCellTemporalCutFrequency;
            obj.retinaParams.IplMagno.V0CompressionParameter = V0CompressionParameter;
            obj.retinaParams.IplMagno.localAdaptintegration_tau = localAdaptintegration_tau;
            obj.retinaParams.IplMagno.localAdaptintegration_k = localAdaptintegration_k;
        end
        
        % method which allows retina to be applied on an input image, after being run, encapsulated retina module is ready to deliver its outputs using dedicated acccessors, see getParvo and getMagno methods
        % @param inputImage : the input cv::Mat image to be processed, can be gray level or BGR coded in any format (from 8bit to 16bits)
        function [] = run (obj, inputImage)
            if isa(inputImage, 'uint8')
                inputImage = double(inputImage) ./ 255;
            else
                assert(isa(inputImage, 'double') && max(inputImage(:) <= 1));
            end
            isColor = (size(inputImage, 3) > 1);
            useAdaptiveFiltering = isColor;
            obj.retinaFilter.runFilter(inputImage, useAdaptiveFiltering, false); % process the retina     
        end

        % method that applies a luminance correction (initially High Dynamic Range (HDR) tone mapping) using only the 2 local adaptation stages of the retina parvo channel : photoreceptors level and ganlion cells level. Spatio temporal filtering is applied but limited to temporal smoothing and eventually high frequencies attenuation. This is a lighter method than the one available using the regular run method. It is then faster but it does not include complete temporal filtering nor retina spectral whitening. This is an adptation of the original still image HDR tone mapping algorithm of David Alleyson, Sabine Susstruck and Laurence Meylan's work, please cite:
        % -> Meylan L., Alleysson D., and Susstrunk S., A Model of Retinal Local Adaptation for the Tone Mapping of Color Filter Array Images, Journal of Optical Society of America, A, Vol. 24, N 9, September, 1st, 2007, pp. 2807-2816
        % @param inputImage the input image to process RGB or gray levels
        % @param outputToneMappedImage the output tone mapped image
        % process tone mapping
        function [outputToneMappedImage] = applyFastToneMapping (obj, inputImage)
             if size(inputImage, 3) > 1
                 outputToneMappedImage = obj.retinaFilter.runRGBToneMapping(inputImage, true, obj.retinaParams.OPLandIplParvo.photoreceptorsLocalAdaptationSensitivity, obj.retinaParams.OPLandIplParvo.ganglionCellsSensitivity);
             else
                 outputToneMappedImage = obj.retinaFilter.runGrayToneMapping(inputImage, obj.retinaParams.OPLandIplParvo.photoreceptorsLocalAdaptationSensitivity, obj.retinaParams.OPLandIplParvo.ganglionCellsSensitivity);
             end
        end
        
        %% sets
        
        % clear all retina buffers (equivalent to opening the eyes after a long period of eye close ;o)
        function [] = clearBuffers (obj)
            obj.retinaFilter.clearAllBuffers();
        end
        
        % Activate/desactivate the Magnocellular pathway processing (motion information extraction), by default, it is activated
        % @param activate - scalar logical, true if Magnocellular output should be activated, false if not
        function [] = activateMovingContoursProcessing (obj, activate)
            obj.retinaFilter.activateMovingContoursProcessing(activate);
        end
        
        % Activate/desactivate the Parvocellular pathway processing (contours information extraction), by default, it is activated
        % @param activate - scalar logical, true if Parvocellular (contours information extraction) output should be activated, false if not
        function [] = activateContoursProcessing (obj, activate)
            obj.retinaFilter.activateContoursProcessing(activate);
        end
        
        % activate color saturation as the final step of the color demultiplexing process
        % -> this saturation is a sigmoide function applied to each channel of the demultiplexed image.
        % @param saturateColors - scalar logical, activates color saturation (if true) or deactivate (if false)
        % @param colorSaturationValue - scalar double, the saturation factor
        function [] = setColorSaturation (obj, saturateColors, colorSaturationValue)
            if ~exist('saturateColors', 'var') || isempty(saturateColors)
                saturateColors = true;
            end
            if ~exist('colorSaturationValue', 'var') || isempty(colorSaturationValue)
                colorSaturationValue = 4;
            end
            obj.retinaFilter.setColorSaturation(saturateColors, colorSaturationValue);
        end
        
        %% gets
        
        % retreive retina input buffer size
        function [nRows,nCols] = getInputSize (obj)
            nRows = obj.retinaFilter.getInputNBrows();
            nCols = obj.retinaFilter.getInputNBcolumns();
        end
        % retreive retina output buffer size
        function [nRows,nCols] = getOutputSize (obj)
            nRows = obj.retinaFilter.getOutputNBrows();
            nCols = obj.retinaFilter.getOutputNBcolumns();
        end
        % @return the current parameters setup
        function [retVal] = getParameters (obj)
            retVal = obj.retinaParams;
        end
        
        % accessor of the details channel of the retina (models foveal vision)
        function [retinaOutput_parvo] = getParvo (obj)
            if obj.retinaFilter.getColorMode()
                retinaOutput_parvo = obj.retinaFilter.getColorOutput();
            else
                retinaOutput_parvo = obj.retinaFilter.getContours();
            end
        end
        % accessor of the motion channel of the retina (models peripheral vision)
        function [retinaOutput_magno] = getMagno (obj)
            retinaOutput_magno = obj.retinaFilter.getMovingContours();
        end

        % parameters setup display method
        % @return a string which contains formatted parameters information
        function [outmessage] = printSetup (obj)
            % OPL and IPL parvo setup
            outmessage = ['Current Retina instance setup:',...
                    '\nOPLandIPLparvo{',...
                    '\n\t colorMode : ',num2str(obj.retinaParams.OPLandIplParvo.colorMode),...
                    '\n\t normalizeParvoOutput :',num2str(obj.retinaParams.OPLandIplParvo.normaliseOutput),...
                    '\n\t photoreceptorsLocalAdaptationSensitivity : ',num2str(obj.retinaParams.OPLandIplParvo.photoreceptorsLocalAdaptationSensitivity),...
                    '\n\t photoreceptorsTemporalConstant : ',num2str(obj.retinaParams.OPLandIplParvo.photoreceptorsTemporalConstant),...
                    '\n\t photoreceptorsSpatialConstant : ',num2str(obj.retinaParams.OPLandIplParvo.photoreceptorsSpatialConstant),...
                    '\n\t horizontalCellsGain : ',num2str(obj.retinaParams.OPLandIplParvo.horizontalCellsGain),...
                    '\n\t hcellsTemporalConstant : ',num2str(obj.retinaParams.OPLandIplParvo.hcellsTemporalConstant),...
                    '\n\t hcellsSpatialConstant : ',num2str(obj.retinaParams.OPLandIplParvo.hcellsSpatialConstant),...
                    '\n\t parvoGanglionCellsSensitivity : ',num2str(obj.retinaParams.OPLandIplParvo.ganglionCellsSensitivity),...
                    '}\n'];

            % IPL magno setup
            outmessage = [outmessage,'Current Retina instance setup :',...
                    '\nIPLmagno{',...
                    '\n\t normaliseOutput : ',num2str(obj.retinaParams.IplMagno.normaliseOutput),...
                    '\n\t parasolCells_beta : ',num2str(obj.retinaParams.IplMagno.parasolCells_beta),...
                    '\n\t parasolCells_tau : ',num2str(obj.retinaParams.IplMagno.parasolCells_tau),...
                    '\n\t parasolCells_k : ',num2str(obj.retinaParams.IplMagno.parasolCells_k),...
                    '\n\t amacrinCellsTemporalCutFrequency : ',num2str(obj.retinaParams.IplMagno.amacrinCellsTemporalCutFrequency),...
                    '\n\t V0CompressionParameter : ',num2str(obj.retinaParams.IplMagno.V0CompressionParameter),...
                    '\n\t localAdaptintegration_tau : ',num2str(obj.retinaParams.IplMagno.localAdaptintegration_tau),...
                    '\n\t localAdaptintegration_k : ',num2str(obj.retinaParams.IplMagno.localAdaptintegration_k),...
                    '}'];
        end
    end
end
