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
classdef RetinaFilter < BasicRetinaFilter
    properties (SetAccess = private)
        % processing activation flags
        useParvoOutput(1,1) logical
        useMagnoOutput(1,1) logical

        % filter stability controls
        ellapsedFramesSinceLastReset(1,1)
        globalTemporalConstant(1,1)

        % private template buffers and related access pointers
        retinaParvoMagnoMappedFrame
        retinaParvoMagnoMapCoefTable
        
        % private objects of the class
        photoreceptorPrefilter(1,1) % BasicRetinaFilter
        parvoRetinaFilter(1,1) % ParvoRetinaFilter
        magnoRetinaFilter(1,1) % MagnoRetinaFilter
        colorEngine(1,1) % RetinaColor
        photoreceptorLogSampling % optional step - may be []. type ImageLogPolProjection*

        normalizeParvoOutput(1,1) logical
        normalizeMagnoOutput(1,1) logical
        useColorMode(1,1) logical
    end
    
    
    methods
        % constructor of the retina filter model with log sampling of the input frame (models the photoreceptors log sampling (central high resolution fovea and lower precision borders))
        % @param sizeRows: number of rows of the input image
        % @param sizeCols: number of columns of the input image
        % @param useRetinaLogSampling - scalar logical, activate retina log sampling, if true, the 2 following parameters can be used
        % @param reductionFactor - scalar double, only usefull if param useRetinaLogSampling=true, specifies the reduction factor of the output frame (as the center (fovea) is high resolution and corners can be underscaled, then a reduction of the output is allowed without precision leak
        % @param samplingStrength - scalar double, only usefull if param useRetinaLogSampling=true, specifies the strength of the log scale that is applied
        % @param samplingMethod - scalar int (enum), specifies which kind of color sampling will be used
        % @param isColor - scalar logical, specifies if the retina works with color (true) or if it only does grayscale processing (false), can be adjusted online by the use of setColorMode method
        % standard constructor without any log sampling of the input frame
        function [obj] = RetinaFilter (nRows, nCols, useRetinaLogSampling, reductionFactor, samplingStrength, samplingMethod, isColor)
            obj.useColorMode = isColor;
            
            if useRetinaLogSampling
                nOutRows = nRows / reductionFactor; % output size of obj.photoreceptorLogSampling
                nOutCols = nCols / reductionFactor; % output size of obj.photoreceptorLogSampling
            else
                nOutRows = nRows;
                nOutCols = nCols;
            end
            
            obj.photoreceptorPrefilter = BasicRetinaFilter(nOutRows, nOutCols, 4, useRetinaLogSampling);
            obj.parvoRetinaFilter      = ParvoRetinaFilter(nOutRows, nOutCols);
            obj.magnoRetinaFilter      = MagnoRetinaFilter(nOutRows, nOutCols);
            obj.colorEngine            = RetinaColor(nOutRows, nOutCols, samplingMethod);
            if useRetinaLogSampling
                obj.photoreceptorLogSampling = ImageLogPolProjection(nRows, nCols, 1, obj.useColorMode);
                obj.photoreceptorLogSampling.initProjection(reductionFactor, samplingStrength);
            end

            % set default processing activities
            obj.useParvoOutput = true;
            obj.useMagnoOutput = true;
            
            obj.createHybridTable(); % create hybrid output and related coefficient table

            obj.setGlobalParameters(); % set default parameters
            % stability controls values init
            obj.setInitPeriodCount();
            obj.globalTemporalConstant = 25;
            obj.clearAllBuffers();
        end

        % function that clears all buffers of the object
        function [] = clearAllBuffers (obj)
            obj.photoreceptorPrefilter.clearAllBuffers();
            obj.parvoRetinaFilter.clearAllBuffers();
            obj.magnoRetinaFilter.clearAllBuffers();
            obj.colorEngine.clearAllBuffers();
            if ~isempty(obj.photoreceptorLogSampling)
                obj.photoreceptorLogSampling.clearAllBuffers();
            end
            obj.setInitPeriodCount(); % stability controls value init
        end

        % Input buffer checker: check if the passed image buffer corresponds to retina filter expectations
        % @param input - numeric matrix, the input image
        % @param isColor - scalar logical, specify if the input should be considered by the retina as colored
        % @return false if not compatible, true otherwise
        function [] = checkInput (obj, input)
            inputTarget = obj.photoreceptorPrefilter; %type = BasicRetinaFilter
            if ~isempty(obj.photoreceptorLogSampling)
                inputTarget = obj.photoreceptorLogSampling;
            end
            assert(numel(input) == inputTarget.getNBpixels() || numel(input) == (inputTarget.getNBpixels()*3), 'input buffer size does not match retina buffer size');
        end

        % run the initilized retina filter, after this call all retina outputs are updated
        % @param imageInput - numeric matrix, the input image, can be grayscale or RGB image respecting the size specified at the constructor level
        % @param useAdaptiveFiltering - scalar logical, set true if you want to use adaptive color demultilexing (solve some color artifact problems), see RetinaColor for citation references
        % @param processRetinaParvoMagnoMapping - scalar logical, tells if the main outputs takes into account the mapping of the Parvo and Magno channels on the retina (centred parvo (fovea) and magno outside (parafovea))
        % -> note that if color mode is activated and processRetinaParvoMagnoMapping==true, then the demultiplexed color frame (accessible through getColorOutput() will be a color contours frame in the fovea and gray level moving contours outside
        % main function that runs the filter for a given input frame
        % run the color multiplexing if needed and compute each sub filter of the retina:
            % -> local adaptation
            % -> contours OPL extraction
            % -> moving contours extraction
        function [] = runFilter (obj, imageInput, useAdaptiveFiltering, processRetinaParvoMagnoMapping)
            obj.checkInput(imageInput);
            
            obj.ellapsedFramesSinceLastReset = obj.ellapsedFramesSinceLastReset + 1; % stability controls value update
            
            % pointer to the appropriate input data after input is processed,
            % if color or something else must be considered, specific preprocessing are applied
            selectedPhotoreceptorsLocalAdaptationInput = imageInput;
            selectedPhotoreceptorsColorInput = imageInput;

            %********** Following is input data specific photoreceptors processing
            if ~isempty(obj.photoreceptorLogSampling)
                obj.photoreceptorLogSampling.runProjection(imageInput, obj.useColorMode);
                selectedPhotoreceptorsColorInput = obj.photoreceptorLogSampling.getSampledFrame();
                selectedPhotoreceptorsLocalAdaptationInput = obj.photoreceptorLogSampling.getSampledFrame();
            end
            
            if obj.useColorMode
                obj.colorEngine.runColorMultiplexing(selectedPhotoreceptorsColorInput, false);
                selectedPhotoreceptorsLocalAdaptationInput = (obj.colorEngine.getMultiplexedFrame());
            end
            %% ********** Following is generic Retina processing
            obj.photoreceptorPrefilter.filterOutput = obj.photoreceptorPrefilter.runFilter_LocalAdaptation(selectedPhotoreceptorsLocalAdaptationInput, obj.parvoRetinaFilter.getHorizontalCellsOutput());
            
            obj.parvoRetinaFilter.filterOutput = obj.parvoRetinaFilter.runFilter(obj.photoreceptorPrefilter.filterOutput, obj.useParvoOutput);
            if obj.useParvoOutput
                obj.parvoRetinaFilter.filterOutput = obj.parvoRetinaFilter.normalizeGrayOutputCentredSigmoide(0, 2.0, obj.parvoRetinaFilter.filterOutput); % models the saturation of the cells, usefull for visualisation of the ON-OFF Parvo Output, Bipolar cells outputs do not change !!!
                obj.parvoRetinaFilter.filterOutput = obj.parvoRetinaFilter.centerReductImageLuminance(); % best for further spectrum analysis
                if obj.normalizeParvoOutput
                    obj.parvoRetinaFilter.filterOutput = obj.parvoRetinaFilter.normalizeGrayOutput(obj.parvoRetinaFilter.filterOutput);
                end
            end
            
            if obj.useParvoOutput && obj.useMagnoOutput
                obj.magnoRetinaFilter.filterOutput = obj.magnoRetinaFilter.runFilter(obj.parvoRetinaFilter.getBipolarCellsON(), obj.parvoRetinaFilter.getBipolarCellsOFF());
                if obj.normalizeMagnoOutput
                    obj.magnoRetinaFilter.filterOutput = obj.magnoRetinaFilter.normalizeGrayOutput(obj.magnoRetinaFilter.filterOutput);
                end
            end

            if obj.useParvoOutput && obj.useMagnoOutput && processRetinaParvoMagnoMapping
                obj.processRetinaParvoMagnoMapping();
                if obj.useColorMode
                    obj.colorEngine.runColorDemultiplexing(obj.retinaParvoMagnoMappedFrame, useAdaptiveFiltering);
                end
                return;
            end
            if obj.useParvoOutput && obj.useColorMode
                obj.colorEngine.runColorDemultiplexing(obj.parvoRetinaFilter.filterOutput, useAdaptiveFiltering);
            end
        end
        
        % runs tone mapping on gray image
        % the algorithm is based on David Alleyson, Sabine Susstruck and Laurence Meylan's work, please cite:
        % -> Meylan L., Alleysson D., and S�sstrunk S., A Model of Retinal Local Adaptation for the Tone Mapping of Color Filter Array Images, Journal of Optical Society of America, A, Vol. 24, N� 9, September, 1st, 2007, pp. 2807-2816
        % get the resulting gray frame by calling function getParvoColor()
        % @param grayImageInput - numeric matrix, the input image, respecting the size specified at the constructor level
        % @param photoreceptorsCompression - scalar double, sets the log compression parameters applied at the photoreceptors level (enhance luminance in dark areas)
        % @param ganglionCellsCompression - scalar double, sets the log compression applied at the gnaglion cells output (enhance contrast)
        % run the initilized retina filter in order to perform gray image tone mapping, after this call all retina outputs are updated
        function [grayImageOutput] = runGrayToneMapping (obj, grayImageInput, photoreceptorsCompression, ganglionCellsCompression)
            obj.checkInput(grayImageInput, false);
            
            % stability controls value update
            obj.ellapsedFramesSinceLastReset = obj.ellapsedFramesSinceLastReset + 1;

            grayImageOutput = zeros(size(grayImageInput), 'like', grayImageInput);

            % apply tone mapping on the multiplexed image
            % -> photoreceptors local adaptation (large area adaptation)
            grayImageOutput = obj.photoreceptorPrefilter.runFilter_LPfilter(grayImageInput, grayImageOutput, 3); % compute low pass filtering modeling the horizontal cells filtering to acess local luminance
            obj.photoreceptorPrefilter.setV0CompressionParameterToneMapping(1 - photoreceptorsCompression, 1 * grayImageOutput.sum() / obj.photoreceptorPrefilter.getNBpixels());
            temp2 = obj.photoreceptorPrefilter.runFilter_LocalAdaptation(grayImageInput, grayImageOutput); % adapt contrast to local luminance

            % -> ganglion cells local adaptation (short area adaptation)
            grayImageOutput = obj.photoreceptorPrefilter.runFilter_LPfilter(temp2, grayImageOutput, 2); % compute low pass filtering (high cut frequency (remove spatio-temporal noise)
            obj.photoreceptorPrefilter.setV0CompressionParameterToneMapping(1 - ganglionCellsCompression, 1 * temp2.sum() / obj.photoreceptorPrefilter.getNBpixels());
            grayImageOutput = obj.photoreceptorPrefilter.runFilter_LocalAdaptation(temp2, grayImageOutput); % adapt contrast to local luminance
        end

        % run the initilized retina filter in order to perform color tone mapping applied on an RGB image, after this call the color output of the retina is updated (use function getColorOutput() to grab it)
        % the algorithm is based on David Alleyson, Sabine Susstruck and Laurence Meylan's work, please cite:
        % -> Meylan L., Alleysson D., and S�sstrunk S., A Model of Retinal Local Adaptation for the Tone Mapping of Color Filter Array Images, Journal of Optical Society of America, A, Vol. 24, N� 9, September, 1st, 2007, pp. 2807-2816
        % get the resulting RGB frame by calling function getParvoColor()
        % @param RGBimageInput - numeric matrix, the input image, respecting the size specified at the constructor level
        % @param useAdaptiveFiltering - scalar constant, set true if you want to use adaptive color demultilexing (solve some color artefact problems), see RetinaColor for citation references
        % @param photoreceptorsCompression - scalar double, sets the log compression parameters applied at the photoreceptors level (enhance luminance in dark areas)
        % @param ganglionCellsCompression - scalar double, sets the log compression applied at the ganglion cells output (enhance contrast)
        % run the initilized retina filter in order to perform color tone mapping, after this call all retina outputs are updated
        function [RGBimageOutput] = runRGBToneMapping (obj, RGBimageInput, useAdaptiveFiltering, photoreceptorsCompression, ganglionCellsCompression)
            obj.checkInput(RGBimageInput, true);

            % multiplex the image with the color sampling method specified in the constructor
            obj.colorEngine.runColorMultiplexing(RGBimageInput);

            % apply tone mapping on the multiplexed image
            RGBimageOutput = obj.runGrayToneMapping(obj.colorEngine.getMultiplexedFrame(), photoreceptorsCompression, ganglionCellsCompression);

            % demultiplex tone maped image
            obj.colorEngine.runColorDemultiplexing(RGBimageOutput, useAdaptiveFiltering);
            obj.colorEngine.getMultiplexedFrame();
            obj.parvoRetinaFilter.getPhotoreceptorsLPfilteringOutput();

            obj.colorEngine.normalizeRGBOutput(); % normalize result

            RGBimageOutput = obj.colorEngine.getDemultiplexedColorFrame();
        end
        
        
        % set up function of the retina filter
        % @param normalizeParvoOutput_0_maxOutputValue - scalar logical, specifies if the Parvo cellular output should be normalized between 0 and max value, in order to remain at a null mean value, true value is recommended for visualisation
        % @param normalizeMagnoOutput_0_maxOutputValue - scalar logical, specifies if the Magno cellular output should be normalized between 0 and max value, setting true may be hazardous because it can enhace the noise response when nothing is moving
        % setup parameters function and global data filling
        function [] = setGlobalParameters (obj, normalizeParvoOutput, normalizeMagnoOutput)
            if(nargin < 3)
                normalizeParvoOutput = false;
                normalizeMagnoOutput = false;
            end
            obj.normalizeParvoOutput = normalizeParvoOutput;
            obj.normalizeMagnoOutput = normalizeMagnoOutput;
            obj.photoreceptorPrefilter.setV0CompressionParameter3(0.9);
            obj.photoreceptorPrefilter.setLPfilterParameters(10, 0, 1.5, 1); % keeps low pass filter with high cut frequency in memory (usefull for the tone mapping function)
            obj.photoreceptorPrefilter.setLPfilterParameters(10, 0, 3.0, 2); % keeps low pass filter with low cut frequency in memory (usefull for the tone mapping function)
            obj.photoreceptorPrefilter.setLPfilterParameters(0, 0, 10, 3); % keeps low pass filter with low cut frequency in memory (usefull for the tone mapping function)
            obj.parvoRetinaFilter.setV0CompressionParameter3(0.9);
            obj.magnoRetinaFilter.setV0CompressionParameter3(0.7);
            obj.setInitPeriodCount(); % stability controls value init
        end

        % setup the local luminance adaptation capability
        % @param V0CompressionParameter - scalar double, the compression strengh of the photoreceptors local adaptation output - a high value increases sensitivity to low values, causing the output to saturate faster
        function [] = setPhotoreceptorsLocalAdaptationSensitivity (obj, V0CompressionParameter)
            obj.photoreceptorPrefilter.setV0CompressionParameter1(1 - V0CompressionParameter);
            obj.setInitPeriodCount();
        end

        % setup the local luminance adaptation capability
        % @param V0CompressionParameter - scalar double, the compression strengh of the parvocellular pathway (details) local adaptation output - a high value increases sensitivity to low values, causing the output to saturate faster
        function [] = setParvoGanglionCellsLocalAdaptationSensitivity (obj, V0CompressionParameter)
            obj.parvoRetinaFilter.setV0CompressionParameter1(V0CompressionParameter);
            obj.setInitPeriodCount();
        end

        % setup the local luminance adaptation area of integration
        % @param spatialResponse - scalar double, the spatial constant of the low pass filter applied on the bipolar cells output in order to compute local contrast mean values
        % @param temporalResponse - scalar double, the spatial constant of the low pass filter applied on the bipolar cells output in order to compute local contrast mean values (generally set to zero: immediate response)
        function [] = setGanglionCellsLocalAdaptationLPfilterParameters (obj, spatialResponse, temporalResponse)
            obj.parvoRetinaFilter.setGanglionCellsLocalAdaptationLPfilterParameters(temporalResponse, spatialResponse);
            obj.setInitPeriodCount();
        end

        % setup the local luminance adaptation capability
        % @param V0CompressionParameter - scalar double, the compression strengh of the magnocellular pathway (motion) local adaptation output - a high value increases sensitivity to low values, causing the output to saturate faster
        function [] = setMagnoGanglionCellsLocalAdaptationSensitivity (obj, V0CompressionParameter)
            obj.magnoRetinaFilter.setV0CompressionParameter1(V0CompressionParameter);
            obj.setInitPeriodCount();
        end

        % setup the OPL and IPL parvo channels
        % @param beta1 - scalar double, gain of the horizontal cells network, if 0, then the mean value of the output is zero (default value), if the parameter is near 1, the amplitude is boosted but it should only be used for values rescaling, if needed
        % @param tau1 - scalar double, the time constant of the first order low pass filter of the photoreceptors, use it to cut high temporal frequencies (noise or fast motion), unit is frames, typical value is 1 frame
        % @param k1 - scalar double, the spatial constant of the first order low pass filter of the photoreceptors, use it to cut high spatial frequencies (noise or thick contours), unit is pixels, typical value is 1 pixel
        % @param beta2 - scalar double, gain of the horizontal cells network, if 0, then the mean value of the output is zero, if the parameter is near 1, then the luminance is not filtered and is still reachable at the output, typical value is 0
        % @param tau2 - scalar double, the time constant of the first order low pass filter of the horizontal cells, use it to cut low temporal frequencies (local luminance variations), unit is frames, typical value is 1 frame
        % @param k2 - scalar double, the spatial constant of the first order low pass filter of the horizontal cells, use it to cut low spatial frequencies (local luminance), unit is pixels, typical value is 5 pixel, this value is also used for local contrast computing when computing the local contrast adaptation at the ganglion cells level (Inner Plexiform Layer parvocellular channel model)
        % @param V0CompressionParameter - scalar double, the compression strengh of the ganglion cells local adaptation output, a high value increases the low value sensitivity, saturating the output faster
        function [] = setOPLandParvoParameters (obj, beta1, tau1, k1, beta2, tau2, k2, V0CompressionParameter)
            obj.parvoRetinaFilter.setOPLandParvoFiltersParameters(beta1, tau1, k1, beta2, tau2, k2);
            obj.parvoRetinaFilter.setV0CompressionParameter1(V0CompressionParameter);
            obj.setInitPeriodCount();
        end

        % set parameters values for the Inner Plexiform Layer (IPL) magnocellular channel
        % @param parasolCells_beta - scalar double, the low pass filter gain used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), typical value is 0
        % @param parasolCells_tau - scalar double, the low pass filter time constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is frame, typical value is 0 (immediate response)
        % @param parasolCells_k - scalar double, the low pass filter spatial constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is pixels, typical value is 5
        % @param amacrinCellsTemporalCutFrequency - scalar double, the time constant of the first order high pass fiter of the magnocellular way (motion information channel), unit is frames, tipical value is 5
        % @param V0CompressionParameter - scalar double, the compression strengh of the ganglion cells local adaptation output, set a value between 160 and 250 for best results, a high value increases the low value sensitivity, saturating the output faster
        % @param localAdaptintegration_tau - scalar double, specifies the temporal constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation
        % @param localAdaptintegration_k - scalar double, specifies the spatial constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation
        function [] = setMagnoCoefficientsTable (obj, parasolCells_beta, parasolCells_tau, parasolCells_k, amacrinCellsTemporalCutFrequency, V0CompressionParameter, localAdaptintegration_tau, localAdaptintegration_k)
            obj.magnoRetinaFilter.setCoefficientsTable(parasolCells_beta, parasolCells_tau, parasolCells_k, amacrinCellsTemporalCutFrequency, localAdaptintegration_tau, localAdaptintegration_k);
            obj.magnoRetinaFilter.setV0CompressionParameter1(V0CompressionParameter);
            obj.setInitPeriodCount();
        end

        % set if the parvo output should be normalized (for display purpose generally)
        % @param normalizeParvoOutput_0_maxOutputValue - scalar logical, true if normalization should be done
        function [] = activateNormalizeParvoOutput (obj, normalizeParvoOutput)
            obj.normalizeParvoOutput = normalizeParvoOutput;
        end

        % set if the magno output should be normalized (for display purpose generally). If nothing is moving, this will cause noise to be enanced
        % @param normalizeMagnoOutput_0_maxOutputValue - scalar logical, true if normalization should be done
        function [] = activateNormalizeMagnoOutput (obj, normalizeMagnoOutput)
            obj.normalizeMagnoOutput = normalizeMagnoOutput;
        end
        
        % @param useMagnoOutput - true if Magnoocellular output should be activated, false if not
        function [] = activateMovingContoursProcessing (obj, useMagnoOutput)
            obj.useMagnoOutput = useMagnoOutput;
        end
        
        % @param useParvoOutput - true if Parvocellular output should be activated, false if not
        function [] = activateContoursProcessing (obj, useParvoOutput)
            obj.useParvoOutput = useParvoOutput;
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
            obj.colorEngine.setColorSaturation(saturateColors, colorSaturationValue);
        end
        
        % apply to the retina color output the Krauskopf transformation which leads to an opponent color system: output colorspace if Acr1cr2 if input of the retina was LMS color space
        % @param result: the input buffer to fill with the transformed colorspace retina output
        function [result] = applyKrauskopfLMS2Acr1cr2Transform (obj, result)
            result = obj.colorEngine.applyKrauskopfLMS2Acr1cr2Transform(result);
        end

        % apply to the retina color output the Krauskopf transformation which leads to an opponent color system: output colorspace if Acr1cr2 if input of the retina was LMS color space
        % @param result: the input buffer to fill with the transformed colorspace retina output
        function [result] = applyLMS2LabTransform (obj, result)
            result = obj.colorEngine.applyLMS2LabTransform(result);
        end
        
        %% gets
        
        % method to retrieve the foveal parvocellular pathway response (no details energy in parafovea)
        % @param parvoParafovealResponse: buffer that will be filled with the response of the magnocellular pathway in the parafoveal area
        % @return true if process succeeded (if buffer exists, is its size matches retina size, if magno channel is activated and if mapping is initialized)
        function [retVal,parvoFovealResponse] = getParvoFoveaResponse (obj, parvoFovealResponse)
            if ~obj.useParvoOutput
                retVal = false;
                return;
            end
            assert(numel(parvoFovealResponse) == obj.parvoRetinaFilter.getNBpixels()); 
            parvoFovealResponse = obj.parvoRetinaFilter.filterOutput .* obj.retinaParvoMagnoMapCoefTable(:, 1);
            retVal = true;
        end
         
        % method to retrieve the parafoveal magnocellular pathway response (no motion energy in fovea)
        % @param magnoParafovealResponse: buffer that will be filled with the response of the magnocellular pathway in the parafoveal area
        % @return true if process succeeded (if buffer exists, is its size matches retina size, if magno channel is activated and if mapping is initialized)
        % method to retrieve the parafoveal magnocellular pathway response (no energy motion in fovea)
        function [retVal,magnoParafovealResponse] = getMagnoParaFoveaResponse (obj, magnoParafovealResponse)
            if ~obj.useMagnoOutput
                retVal = false;
                return;
            end
            assert(numel(magnoParafovealResponse) == obj.magnoRetinaFilter.getNBpixels());
            magnoParafovealResponse = obj.magnoRetinaFilter.filterOutput .* obj.retinaParvoMagnoMapCoefTable(:, 2);
            retVal = true;
        end

        % @return the input image sampled by the photoreceptors spatial sampling
        function [retVal] = getPhotoreceptorsSampledFrame (obj)
            retVal = obj.photoreceptorLogSampling.getSampledFrame();
        end
        % @return photoreceptors output, locally adapted luminance only, no high frequency spatio-temporal noise reduction at the next retina processing stages, use getPhotoreceptors method to get complete photoreceptors output
        function [retVal] = getLocalAdaptation (obj)
            retVal = obj.photoreceptorPrefilter.filterOutput;
        end
        % @return photoreceptors output: locally adapted luminance and high frequency spatio-temporal noise reduction, high luminance is a little saturated at this stage, but this is corrected naturally at the next retina processing stages
        function [retVal] = getPhotoreceptors (obj)
            retVal = obj.parvoRetinaFilter.getPhotoreceptorsLPfilteringOutput();
        end
        % @return the local luminance of the processed frame (the horizontal cells output)
        function [retVal] = getHorizontalCells (obj)
            retVal = obj.parvoRetinaFilter.getHorizontalCellsOutput();
        end
        % @return true if parvocellular output is activated, false if not
        function [retVal] = areContoursProcessed (obj)
            retVal = obj.useParvoOutput;
        end
        % @return the parvocellular contours information (details), should be used at the fovea level
        function [retVal] = getContours (obj)
            if obj.useColorMode
                retVal = obj.colorEngine.getLuminance();
            else
                retVal = obj.parvoRetinaFilter.filterOutput;
            end
        end
        % @return the parvocellular contours ON information (details), should be used at the fovea level
        function [retVal] = getContoursON (obj)
            retVal = obj.parvoRetinaFilter.getParvoON(); % Parvocellular ON output
        end
        % @return the parvocellular contours OFF information (details), should be used at the fovea level
        function [retVal] = getContoursOFF (obj)
            retVal = obj.parvoRetinaFilter.getParvoOFF(); % Parvocellular OFF output
        end
        % @return true if Magnocellular output is activated, false if not
        function [retVal] = areMovingContoursProcessed (obj)
            retVal = obj.useMagnoOutput;
        end
        % @return the magnocellular moving contours information (motion), should be used at the parafovea level without post-processing
        function [retVal] = getMovingContours (obj)
            retVal = obj.magnoRetinaFilter.filterOutput; % Magnocellular output
        end
        % @return the magnocellular moving contours information (motion), should be used at the parafovea level with assymetric sigmoide post-processing which saturates motion information
        function [retVal] = getMovingContoursSaturated (obj)
            retVal = obj.magnoRetinaFilter.getMagnoYsaturated(); % Saturated Magnocellular output
        end
        % @return the magnocellular moving contours ON information (motion), should be used at the parafovea level without post-processing
        function [retVal] = getMovingContoursON (obj)
            retVal = obj.magnoRetinaFilter.getMagnoON(); % Magnocellular ON output
        end
        % @return the magnocellular moving contours OFF information (motion), should be used at the parafovea level without post-processing
        function [retVal] = getMovingContoursOFF (obj)
            retVal = obj.magnoRetinaFilter.getMagnoOFF(); % Magnocellular OFF output
        end
        % @return a gray level image with center Parvo and peripheral Magno X channels
        %    -> will be accessible even if color mode is activated (but the image is color sampled so quality is poor), but get the same thing but in color by the use of function getParvoColor()
        function [retVal] = getRetinaParvoMagnoMappedOutput (obj)
            retVal = obj.retinaParvoMagnoMappedFrame; % return image with center Parvo and peripheral Magno channels
        end
        % @return the irregular low pass filter ouput at the photoreceptors level
        function [retVal] = getIrregularLPfilteredInputFrame (obj)
            retVal = obj.photoreceptorLogSampling.getIrregularLPfilteredInputFrame();
        end
        % color processing dedicated functions
        % @return the parvo channel (contours, details) of the processed frame, grayscale output
        function [retVal] = getParvoContoursChannel (obj)
            retVal = obj.colorEngine.getLuminance();
        end
        % color processing dedicated functions
        % @return the chrominance of the processed frame (same colorspace as the input output, usually RGB)
        function [retVal] = getParvoChrominance (obj)
            retVal = obj.colorEngine.getChrominance(); % only retreive chrominance
        end
        % color processing dedicated functions
        % @return the parvo + chrominance channels of the processed frame (same colorspace as the input output, usually RGB)
        function [retVal] = getColorOutput (obj)
            retVal = obj.colorEngine.getDemultiplexedColorFrame(); % retrieve luminance+chrominance
        end
        % @return true if color mode is activated, false if gray levels processing
        function [retVal] = getColorMode (obj)
            retVal = obj.useColorMode;
        end
        % @return number of rows of the filter
        function [retVal] = getInputNBrows (obj)
            if ~isempty(obj.photoreceptorLogSampling)
                retVal = obj.photoreceptorLogSampling.getNBrows();
            else
                retVal = obj.photoreceptorPrefilter.getNBrows();
            end
        end
        % @return number of columns of the filter
        function [retVal] = getInputNBcolumns (obj)
            if ~isempty(obj.photoreceptorLogSampling)
                retVal = obj.photoreceptorLogSampling.getNBcolumns();
            else
                retVal = obj.photoreceptorPrefilter.getNBcolumns();
            end
        end
        % @return number of pixels of the filter
        function [retVal] = getInputNBpixels (obj)
            if ~isempty(obj.photoreceptorLogSampling)
                retVal = obj.photoreceptorLogSampling.getNBpixels();
            else
                retVal = obj.photoreceptorPrefilter.getNBpixels();
            end
        end
        % @return the height of the frame output
        function [retVal] = getOutputNBrows (obj)
            retVal = obj.photoreceptorPrefilter.getNBrows();
        end
        % @return the width of the frame output
        function [retVal] = getOutputNBcolumns (obj)
            retVal = obj.photoreceptorPrefilter.getNBcolumns();
        end
        % @return the numbers of output pixels (width*height) of the images used by the object
        function [retVal] = getOutputNBpixels (obj)
            retVal = obj.photoreceptorPrefilter.getNBpixels();
        end
        % @return true if a sufficient number of processed frames has been done since the last parameters update in order to get the stable state
        function [retVal] = isInitTransitionDone (obj)
            if obj.ellapsedFramesSinceLastReset < obj.globalTemporalConstant
                retVal = false;
            else
                retVal = true;
            end
        end
        % given a distance of a point to the frame's center in the log sampled frame, get this point's distance to center in the image input space 
        % @param projectedRadiusLength - scalar double, the distance to image center in the retina log sampled space
        % @return the distance to image center in the input image space
        function [retVal] = getRetinaSamplingBackProjection (obj, projectedRadiusLength)
            if ~isempty(obj.photoreceptorLogSampling)
                retVal = obj.photoreceptorLogSampling.getOriginalRadiusLength(projectedRadiusLength);
            else
                retVal = projectedRadiusLength;
            end
        end
    end
    
    
    methods (Access = protected)
        % stability controls value init
        function [] = setInitPeriodCount (obj)
            % find out the maximum temporal constant value and apply a security factor
            obj.globalTemporalConstant = obj.parvoRetinaFilter.getPhotoreceptorsTemporalConstant() + obj.parvoRetinaFilter.getHcellsTemporalConstant() + obj.magnoRetinaFilter.getTemporalConstant();
            obj.ellapsedFramesSinceLastReset = 0; % reset frame counter
        end

        function [] = createHybridTable (obj)
            % create hybrid output and related coefficient table
            obj.retinaParvoMagnoMappedFrame = zeros(obj.photoreceptorPrefilter.getNBrows(), obj.photoreceptorPrefilter.getNBcolumns()); %FIX params
            obj.retinaParvoMagnoMapCoefTable = zeros(obj.photoreceptorPrefilter.getNBrows(), obj.photoreceptorPrefilter.getNBcolumns(), 2); % FIX params

            % fill hybridParvoMagnoCoefTable
            halfRows = obj.photoreceptorPrefilter.getNBrows() / 2;
            halfColumns = obj.photoreceptorPrefilter.getNBcolumns() / 2;
            minDistance = min(halfRows, halfColumns) * 0.7;
            for r = 1:obj.photoreceptorPrefilter.getNBrows()
                for c = 1:obj.photoreceptorPrefilter.getNBcolumns()
                    distanceToCenter = sqrt(((r-1)-halfRows) * ((r-1)-halfRows) + ((c-1)-halfColumns) * ((c-1)-halfColumns));
                    if distanceToCenter < minDistance
                        a = 0.5 + 0.5 * cos(pi * distanceToCenter / minDistance);
                    else
                        a = 0;
                    end
                    obj.retinaParvoMagnoMapCoefTable(r, c, 1) = a;
                    obj.retinaParvoMagnoMapCoefTable(r, c, 2) = a;
                end
            end
        end

         function [] = processRetinaParvoMagnoMapping (obj)
            obj.retinaParvoMagnoMappedFrame = obj.parvoRetinaFilter.filterOutput .* obj.retinaParvoMagnoMapCoefTable(:, 1) + magnoXOutput(r,c) .* obj.retinaParvoMagnoMapCoefTable(r, c, 2);
            obj.retinaParvoMagnoMappedFrame = obj.retinaParvoMagnoMappedFrame.normalizeGrayOutput(obj.retinaParvoMagnoMappedFrame);
        end
    end
end
