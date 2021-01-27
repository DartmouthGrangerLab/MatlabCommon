%Eli Bowen
%7/21/2020
%unified wrapper around all of our video filters
%written as a class so that it can store persistent variables (necessary for some video frontends)
classdef VidFilter < handle
    properties (SetAccess = private)
        filters
        nOutChannels(1,1) % scalar double
        
        % filter-specific stuff below
        retina
        patchCache
%         imgSize(1,3) % [nRows,nCols,nChannels] size of frame
    end
    
    
    methods
        %constructor
        %INPUTS:
        %   filters - char or cell array of chars - each char one of 'rgb2gray', 'opponency', 'opponencysplit', 'retina', 'retinagray', 'gabor'
        %       if cell array of chars, filters will be applied in array order
        %   inFormat - 'gray' or 'rgb'
        function [obj] = VidFilter (filters, inFormat)
            validateattributes(filters, {'char','cell'}, {'nonempty','vector'});
            validateattributes(inFormat, {'char'}, {'nonempty','vector'});
            if ischar(filters)
                filters = {filters};
            end
            assert(strcmp(inFormat, 'gray') || strcmp(inFormat, 'rgb'));
            
            obj.filters = filters;
            
            if strcmp(obj.filters{end}, 'rgb2gray')
                obj.nOutChannels = 1;
            elseif strcmp(obj.filters{end}, 'opponency')
                obj.nOutChannels = 3;
            elseif strcmp(obj.filters{end}, 'opponencysplit')
                obj.nOutChannels = 6;
            elseif strcmp(obj.filters{end}, 'retina')
                obj.nOutChannels = 7; % chan1 parvo+, chan1 parvo-, chan2 parvo+, chan2 parvo-, chan3 parvo+, chan3 parvo-, magno
            elseif strcmp(obj.filters{end}, 'retinagray')
                obj.nOutChannels = 3; % parvo+, parvo-, magno
            elseif strcmp(obj.filters{end}, 'gabor')
                nGaborsPerInChannel = 64; % 64 is a function of constants defined in HMAX.m
                if numel(obj.filters) == 1
                    if strcmp(inFormat, 'gray')
                        obj.nOutChannels = 1 * nGaborsPerInChannel;
                    else % 'rgb'
                        obj.nOutChannels = 3 * nGaborsPerInChannel;
                    end
                elseif strcmp(obj.filters{end-1}, 'rgb2gray')
                    obj.nOutChannels = 1 * nGaborsPerInChannel;
                elseif strcmp(obj.filters{end-1}, 'opponency')
                    obj.nOutChannels = 3 * nGaborsPerInChannel;
                elseif strcmp(obj.filters{end-1}, 'opponencysplit')
                    obj.nOutChannels = 6 * nGaborsPerInChannel;
                elseif strcmp(obj.filters{end-1}, 'retina')
                    obj.nOutChannels = 4 * nGaborsPerInChannel;
                elseif strcmp(obj.filters{end-1}, 'retinagray')
                    obj.nOutChannels = 2 * nGaborsPerInChannel;
                end
            else
                error('unknown filter');
            end
        end


        %INPUTS:
        %   img - nRows x nCols x nInChannels frame, can be formatted as uint8 (range 0-->255) or double (range 0-->1)
        %RETURNS:
        %   img - nRows x nCols x obj.nOutChannels usually in same format as input (filters like gabor must return double)
        function [img] = Proc (obj, img)
            validateattributes(img, {'uint8','double'}, {'nonempty', '3d'});
            assert(size(img, 3) == 3 || size(img, 3) == 1);
            
            for i = 1:numel(obj.filters)
                nInChannels = size(img, 3);
                if strcmp(obj.filters{i}, 'rgb2gray')
                    assert(nInChannels == 3);
                    img = RGB2Luminance(img);
                elseif strcmp(obj.filters{i}, 'opponency')
                    assert(nInChannels == 3);
                    img = RGB2Opponent(img);
                elseif strcmp(obj.filters{i}, 'opponencysplit')
                    assert(nInChannels == 3);
                    img = RGB2Opponent(img);
                    
                    % split positive and negative components (currently, "no opponency" is the middle of the range)
                    img = cat(3, img, img);
                    if isa(img, 'uint8') % range is 0-->255
                        % slight weirdness - 254 is the largest possible output value (not 255)
                        img(:,:,1:end/2) = img(:,:,1:end/2) - uint8(128); % all nagatives set to 0 by matlab uint8 standard
                        img(:,:,end/2+1:end) = uint8(127) - img(:,:,end/2+1:end);
                    else % floating points, range is 0-->1
                        img(:,:,1:end/2) = max(0, img(:,:,1:end/2) - 0.5);
                        img(:,:,end/2+1:end) = max(0, 0.5 - img(:,:,end/2+1:end));
                    end
                    img = img .* 2; % return to original dynamic range
                elseif strcmp(obj.filters{i}, 'retina')
                    assert(nInChannels == 3);
                    if isempty(obj.retina)
                        obj.retina = VideoRetina(size(img, 1), size(img, 2), true); %prints lots of junk
                    end
                    [imgP,imgM] = obj.retina.ProcessFrame(img); % verifies img is retina.nRows x retina.nCols
                    img = cat(3, imgP, imgM);
                elseif strcmp(obj.filters{i}, 'retinagray')
                    if isempty(obj.retina)
                        obj.retina = VideoRetina(size(img, 1), size(img, 2), false); %prints lots of junk
                    end
                    [imgP,imgM] = obj.retina.ProcessFrame(img); % verifies img is retina.nRows x retina.nCols
                    img = cat(3, imgP, imgM);
                elseif strcmp(obj.filters{i}, 'gabor')
                    if isempty(obj.patchCache)
                        [s1,~,~,~,~,~,obj.patchCache] = HMAX(img(:,:,1), []);
                    else
                        s1 = HMAX(img(:,:,1), obj.patchCache);
                    end
                    if nInChannels == 1
                        img = cat(3, s1{:});
                    else
                        val = cell(1, nInChannels);
                        val{1} = cat(3, s1{:});
                        for chan = 2:nInChannels
                            [s1,~] = HMAX(img(:,:,chan), obj.patchCache);
                            val{chan} = cat(3, s1{:});
                        end
                        img = cat(3, val{:});
                    end
                else
                    error('unknown filter');
                end
            end
        end
    end
end