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
classdef ParvoRetinaFilter < BasicRetinaFilter
    properties (SetAccess = private)
        % template buffers
        photoreceptorsOutput
        horizontalCellsOutput
        parvocellularOutputON
        parvocellularOutputOFF
        bipolarCellsOutputON
        bipolarCellsOutputOFF
        localAdaptationOFF
        localAdaptationON
        parvocellularOutputONminusOFF
    end
    
    
    methods
        % constructor parameters are only linked to image input size
        % @param nRows: number of rows of the input image
        % @param nCols: number of columns of the input image
        function [obj] = ParvoRetinaFilter (nRows, nCols)
            obj = obj@BasicRetinaFilter(nRows, nCols, 3, false);
            
            obj.photoreceptorsOutput   = zeros(nRows, nCols);
            obj.horizontalCellsOutput  = zeros(nRows, nCols);
            obj.parvocellularOutputON  = zeros(nRows, nCols);
            obj.parvocellularOutputOFF = zeros(nRows, nCols);
            obj.bipolarCellsOutputON   = zeros(nRows, nCols);
            obj.bipolarCellsOutputOFF  = zeros(nRows, nCols);
            obj.localAdaptationOFF     = zeros(nRows, nCols);
            obj.localAdaptationON = zeros(nRows, nCols);
            
            % link to the required local parent adaptation buffers
            obj.parvocellularOutputONminusOFF = obj.filterOutput;

            obj.clearAllBuffers();
        end

        % function that clears all buffers of the object
        function [] = clearAllBuffers (obj)
            clearAllBuffers@BasicRetinaFilter(obj);
            obj.photoreceptorsOutput(:)   = 0;
            obj.horizontalCellsOutput(:)  = 0;
            obj.parvocellularOutputON(:)  = 0;
            obj.parvocellularOutputOFF(:) = 0;
            obj.bipolarCellsOutputON(:)   = 0;
            obj.bipolarCellsOutputOFF(:)  = 0;
            obj.localAdaptationOFF(:)     = 0;
            obj.localAdaptationON(:) = 0;
        end

        % setup the OPL and IPL parvo channels
        % @param beta1 - scalar double, gain of the horizontal cells network, if 0, then the mean value of the output is zero, if the parameter is near 1, the amplitude is boosted but it should only be used for values rescaling, if needed
        % @param tau1 - scalar double, the time constant of the first order low pass filter of the photoreceptors, use it to cut high temporal frequencies (noise or fast motion), unit is frames, typical value is 1 frame
        % @param k1 - scalar double, the spatial constant of the first order low pass filter of the photoreceptors, use it to cut high spatial frequencies (noise or thick contours), unit is pixels, typical value is 1 pixel
        % @param beta2 - scalar double, gain of the horizontal cells network, if 0, then the mean value of the output is zero, if the parameter is near 1, then, the luminance is not filtered and is still reachable at the output, typical value is 0
        % @param tau2 - scalar double, the time constant of the first order low pass filter of the horizontal cells, use it to cut low temporal frequencies (local luminance variations), unit is frames, typical value is 1 frame, as the photoreceptors
        % @param k2 - scalar double, the spatial constant of the first order low pass filter of the horizontal cells, use it to cut low spatial frequencies (local luminance), unit is pixels, typical value is 5 pixel, this value is also used for local contrast computing when computing the local contrast adaptation at the ganglion cells level (Inner Plexiform Layer parvocellular channel model)
        % change the parameters of the filter
        function [] = setOPLandParvoFiltersParameters (obj, beta1, tau1, k1, beta2, tau2, k2)
            obj.setLPfilterParameters(beta1, tau1, k1, 1); % init photoreceptors low pass filter
            obj.setLPfilterParameters(beta2, tau2, k2, 2); % init horizontal cells low pass filter
            obj.setLPfilterParameters(0, tau1, k1, 3); % init parasol ganglion cells low pass filter (default parameters)
        end
        % setup more precisely the low pass filter used for the ganglion cells low pass filtering (used for local luminance adaptation)
        % @param tau - scalar double, time constant of the filter (unit is frame for video processing)
        % @param k - scalar double, spatial constant of the filter (unit is pixels)
        function [] = setGanglionCellsLocalAdaptationLPfilterParameters (obj, tau, k)
            obj.setLPfilterParameters(0, tau, k, 2); % change the parameters of the filter
        end

        % launch filter that runs the OPL spatiotemporal filtering and optionally finalizes IPL Pagno filter (model of the Parvocellular channel of the Inner Plexiform Layer of the retina)
        % @param inputFrame: the input image to be processed, this can be the direct gray level input frame, but a better efficacy is expected if the input is preliminary processed by the photoreceptors local adaptation
        % @param useParvoOutput - scalar logical, set true if the final IPL filtering step is to be computed (local contrast enhancement)
        % @return the processed Parvocellular channel output (updated only if useParvoOutput is true)
        % @details: in any case, after this function call, photoreceptors and horizontal cells output are updated, use getPhotoreceptorsLPfilteringOutput() and getHorizontalCellsOutput() to get them
        % bipolar cells output are accessible (difference between photoreceptors and horizontal cells, ON output has positive values, OFF ouput has negative values), use the following access methods: getBipolarCellsON() and getBipolarCellsOFF()
        % if useParvoOutput is true, the complete Parvocellular channel is computed, more outputs are updated and can be accessed through: getParvoON(), getParvoOFF() and their difference with getOutput()
        % run filter for a new frame input
        % output return is obj.parvocellularOutputONminusOFF
        function [retVal] = runFilter (obj, inputFrame, useParvoOutput)
            obj.photoreceptorsOutput = obj.spatiotemporalLPfilter(inputFrame, obj.photoreceptorsOutput, 1);
            obj.horizontalCellsOutput = obj.spatiotemporalLPfilter(obj.photoreceptorsOutput, obj.horizontalCellsOutput, 2);
            obj.OPL_OnOffWaysComputing();

            if useParvoOutput
                % local adaptation processes on ON and OFF ways
                obj.localAdaptationON = obj.spatiotemporalLPfilter(obj.bipolarCellsOutputON, obj.localAdaptationON, 3);
                obj.parvocellularOutputON = obj.localLuminanceAdaptation(obj.parvocellularOutputON, obj.localAdaptationON, false);
                
                obj.localAdaptationOFF = obj.spatiotemporalLPfilter(obj.bipolarCellsOutputOFF, obj.localAdaptationOFF, 3);
                obj.parvocellularOutputOFF = obj.localLuminanceAdaptation(obj.parvocellularOutputOFF, obj.localAdaptationOFF, false);
                % Final loop that computes the main output of this filter
                % loop that takes the difference between photoreceptor cells output and horizontal cells
                % positive part goes on the ON way, negative pat goes on the OFF way
                obj.parvocellularOutputONminusOFF(:) = obj.parvocellularOutputON(:) - obj.parvocellularOutputOFF(:);
            end
            retVal = obj.parvocellularOutputONminusOFF;
        end
        
        % force filter output to be normalized : data centering and std normalisation
        function [output] = centerReductImageLuminance (obj)
            assert(size(obj.filterOutput, 3) == 1);
            
            meanValue = mean(obj.filterOutput(:)); % compute mean value
            
            inputMinusMean = obj.filterOutput - meanValue;
            stdValue = sqrt(sum(inputMinusMean(:) .* inputMinusMean(:)) / numel(obj.filterOutput)); % compute std value
            
            output = (obj.filterOutput - meanValue) ./ stdValue; % adjust luminance in regard of mean and std value
        end

        %% gets
        
        % @return the output of the photoreceptors filtering step (high cut frequency spatio-temporal low pass filter)
        function [retVal] = getPhotoreceptorsLPfilteringOutput (obj)
            retVal = obj.photoreceptorsOutput;
        end
        % @return the output of the photoreceptors filtering step (low cut frequency spatio-temporal low pass filter)
        function [retVal] = getHorizontalCellsOutput (obj)
            retVal = obj.horizontalCellsOutput;
        end
        % @return the output Parvocellular ON channel of the retina model
        function [retVal] = getParvoON (obj)
            retVal = obj.parvocellularOutputON;
        end
        % @return the output Parvocellular OFF channel of the retina model
        function [retVal] = getParvoOFF (obj)
            retVal = obj.parvocellularOutputOFF;
        end
        % @return the output of the Bipolar cells of the ON channel of the retina model - same as function getParvoON() but without luminance local adaptation
        function [retVal] = getBipolarCellsON (obj)
            retVal = obj.bipolarCellsOutputON;
        end
        % @return the output of the Bipolar cells of the OFF channel of the retina model - same as function getParvoON() but without luminance local adaptation
        function [retVal] = getBipolarCellsOFF (obj)
            retVal = obj.bipolarCellsOutputOFF;
        end
        % @return the photoreceptors's temporal constant
        function [retVal] = getPhotoreceptorsTemporalConstant (obj)
            retVal = obj.filteringCoefficientsTable(1,3);
        end
        % @return the horizontal cells' temporal constant
        function [retVal] = getHcellsTemporalConstant (obj)
            retVal = obj.filteringCoefficientsTable(2,3);
        end
    end
    
    
    methods (Access = private)
        function [] = OPL_OnOffWaysComputing (obj)
            % loop that makes the difference between photoreceptor cells output and horizontal cells
            % positive part goes on the ON way, negative part goes on the OFF way
            pixelDifference = obj.photoreceptorsOutput - obj.horizontalCellsOutput;
            
            % test condition to allow write pixelDifference in ON or OFF buffer and 0 in the over
            isPositive = double(pixelDifference > 0);
            
            % ON and OFF channels writing step
            obj.parvocellularOutputON = isPositive .* pixelDifference;
            obj.bipolarCellsOutputON  = isPositive .* pixelDifference;
            obj.parvocellularOutputOFF = (isPositive-1) .* pixelDifference;
            obj.bipolarCellsOutputOFF  = (isPositive-1) .* pixelDifference;
        end
    end
end
