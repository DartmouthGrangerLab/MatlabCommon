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
classdef MagnoRetinaFilter < BasicRetinaFilter
    properties (SetAccess = private)
        % related pointers to these buffers
        previousInput_ON
        previousInput_OFF
        amacrinCellsTempOutput_ON
        amacrinCellsTempOutput_OFF
        magnoXOutputON
        magnoXOutputOFF
        localProcessBufferON
        localProcessBufferOFF

        % varialbles
        temporalCoefficient(1,1)
    end
    
    
    methods
        % constructor parameters are only linked to image input size
        % @param NBrows: number of rows of the input image
        % @param NBcolumns: number of columns of the input image
        % Constructor and Desctructor of the OPL retina filter
        function [obj] = MagnoRetinaFilter (nRows, nCols)
            obj = obj@BasicRetinaFilter(nRows, nCols, 2, false);
            
            obj.previousInput_ON           = zeros(nRows, nCols);
            obj.previousInput_OFF          = zeros(nRows, nCols);
            obj.amacrinCellsTempOutput_ON  = zeros(nRows, nCols);
            obj.amacrinCellsTempOutput_OFF = zeros(nRows, nCols);
            obj.magnoXOutputON             = zeros(nRows, nCols);
            obj.magnoXOutputOFF            = zeros(nRows, nCols);
            obj.localProcessBufferON       = zeros(nRows, nCols);
            obj.localProcessBufferOFF      = zeros(nRows, nCols);
            
            obj.clearAllBuffers();
        end

        % function that clears all buffers of the object
        function [] = clearAllBuffers (obj)
            clearAllBuffers@BasicRetinaFilter(obj);
            obj.previousInput_ON(:)           = 0;
            obj.previousInput_OFF(:)          = 0;
            obj.amacrinCellsTempOutput_ON(:)  = 0;
            obj.amacrinCellsTempOutput_OFF(:) = 0;
            obj.magnoXOutputON(:)             = 0;
            obj.magnoXOutputOFF(:)            = 0;
            obj.localProcessBufferON(:)       = 0;
            obj.localProcessBufferOFF(:)      = 0;
        end

        % set parameters values
        % @param parasolCell_beta - scalar double, the low pass filter gain used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), typical value is 0
        % @param parasolCell_tau - scalar double, the low pass filter time constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is frames, typical value is 0 (immediate response)
        % @param parasolCell_k - scalar double, the low pass filter spatial constant used for local contrast adaptation at the IPL level of the retina (for ganglion cells local adaptation), unit is pixels, typical value is 5
        % @param amacrinCellTemporalCutFrequency - scalar double, the time constant of the first order high pass fiter of the magnocellular way (motion information channel), unit is frames, typical value is 5
        % @param localAdaptIntegration_tau - scalar double, specifies the temporal constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation
        % @param localAdaptIntegration_k - scalar double, specifies the spatial constant of the low pas filter involved in the computation of the local "motion mean" for the local adaptation computation
        function [] = setCoefficientsTable (obj, parasolCell_beta, parasolCell_tau, parasolCell_k, amacrinCellTemporalCutFrequency, localAdaptIntegration_tau, localAdaptIntegration_k)
            obj.temporalCoefficient = exp(-1 / amacrinCellTemporalCutFrequency);
            % the first set of parameters is dedicated to the low pass filtering property of the ganglion cells
            obj.setLPfilterParameters(parasolCell_beta, parasolCell_tau, parasolCell_k, 1);
            % the second set of parameters is dedicated to the ganglion cells output intergartion for their local adaptation property
            obj.setLPfilterParameters(0, localAdaptIntegration_tau, localAdaptIntegration_k, 2);
        end

        % launch filter that runs all the IPL magno filter (model of the magnocellular channel of the Inner Plexiform Layer of the retina)
        % @param OPL_ON: the output of the bipolar ON cells of the retina (available from the ParvoRetinaFilter class (getBipolarCellsON() function)
        % @param OPL_OFF: the output of the bipolar OFF cells of the retina (available from the ParvoRetinaFilter class (getBipolarCellsOFF() function)
        % @return the processed result without post-processing
        % launch filter that runs all the IPL filters
        function [output] = runFilter (obj, OPL_ON, OPL_OFF)
            % Compute the high pass temporal filter
            [obj.amacrinCellsTempOutput_ON, obj.amacrinCellsTempOutput_OFF, obj.previousInput_ON, obj.previousInput_OFF] = obj.amacrinCellsComputing(OPL_ON, OPL_OFF);
            % apply low pass filtering on ON and OFF ways after temporal high pass filtering
            obj.magnoXOutputON  = obj.spatiotemporalLPfilter(obj.amacrinCellsTempOutput_ON, obj.magnoXOutputON, 1);
            obj.magnoXOutputOFF = obj.spatiotemporalLPfilter(obj.amacrinCellsTempOutput_OFF, obj.magnoXOutputOFF, 1);

            % local adaptation of the ganglion cells to the local contrast of the moving contours
            obj.localProcessBufferON = obj.spatiotemporalLPfilter(obj.magnoXOutputON, obj.localProcessBufferON, 2);
            obj.magnoXOutputON = obj.localLuminanceAdaptation(obj.magnoXOutputON, obj.localProcessBufferON, false);
            obj.localProcessBufferOFF = obj.spatiotemporalLPfilter(obj.magnoXOutputOFF, obj.localProcessBufferOFF,2);
            obj.magnoXOutputOFF = obj.localLuminanceAdaptation(obj.magnoXOutputOFF, obj.localProcessBufferOFF, false); %make true??

            % Compute output
            output = obj.magnoXOutputON + obj.magnoXOutputOFF;
        end
        
        function [output] = normalizeGrayOutputNearZeroCentreredSigmoide (obj)
            sensitivity = 40;
            X0cube = sensitivity .^ 3;
            currentCubeLuminance = obj.filterOutput .^ 3;
            output = 1 .* currentCubeLuminance ./ (currentCubeLuminance+X0cube);
        end

        
        %% gets

        % @return the Magnocellular ON channel filtering output
        function [retVal] = getMagnoON (obj)
            retVal = obj.magnoXOutputON;
        end
        % @return the Magnocellular OFF channel filtering output
        function [retVal] = getMagnoOFF (obj)
            retVal = obj.magnoXOutputOFF;
        end
        % @return the horizontal cells' temporal constant
        function [retVal] = getTemporalConstant (obj)
            retVal = obj.filteringCoefficientsTable(1,3);
        end
    end
    
    
    methods (Access = private)
        % amacrin cells filter : high pass temporal filter
        function [tempOn, tempOff, OPL_ON, OPL_OFF] = amacrinCellsComputing (obj, OPL_ON, OPL_OFF)
            % Compute ON and OFF amacrin cells high pass temporal filter
            magnoXonPixelResult = obj.temporalCoefficient .* (obj.amacrinCellsTempOutput_ON + OPL_ON - obj.previousInput_ON);
            tempOn = double(magnoXonPixelResult>0) .* magnoXonPixelResult;
            
            magnoXoffPixelResult = obj.temporalCoefficient .* (obj.amacrinCellsTempOutput_OFF + OPL_OFF - obj.previousInput_OFF);
            tempOff = double(magnoXoffPixelResult>0) .* magnoXoffPixelResult;
        end
    end
end
