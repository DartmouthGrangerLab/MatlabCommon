% given orientation and receptive field size, returns a Gabor filter
% INPUTS:
%   theta - scalar (numeric) - gabor angle in degrees
%   sz - scalar (numeric) - size of filter in pixels
%   gamma - scalar (numeric) - spatial aspect ratio for the gaussian border "0.23 < gamma < 0.92" (Eli: default was 0.3, but seems like it should always be 1 to me...)
% RETURNS:
%   sqfilter - sz x sz (numeric)
function [sqfilter] = InitGabor (theta, sz, gamma)
    sqfilter = zeros(sz, sz);

    % larger lambda --> broader gaussian, larger wavelength
    lambda = sz * 2 / (4 - 0.025 * (sz - 7)); % tunes the filters' "tightness"
    % Eli thinks lambda should be a lot less than it is currently (the original val)
%     div = 4 - 0.025 * (sz - 7);
    % below same as above (within eps) for filterSz = 7:2:39 (the original values)
%     div = 4:-.05:3.2; % tuning parameter for the filters' "tightness"
    % ^ div: a list of scaling factors tuning the wavelength of the sinusoidal factor ('lambda') in relation to the receptive field sizes ('sz')
    
    sigma = 2 * ((lambda * 0.8) .^ 2); % scales the gaussian to fit into sz (Eli: does a terrible job - the gaussian is still at 0.5 when it hits the edge of the filter)
    multiplier = 2 * pi / lambda; % scales the waveform to fit into sz
    gammaSq = gamma .^ 2;
    center = ceil(sz / 2);
    szL = center - 1;
    szR = sz - szL - 1;
    for i = -szL:szR
        for j = -szL:szR
            if sqrt(i^2+j^2) <= sz / 2
                x = i * cosd(theta) - j * sind(theta);
                y = i * sind(theta) + j * cosd(theta);
                sqfilter(j+center,i+center) = exp(-(x^2 + gammaSq * y^2) / sigma) * cos(multiplier * x);
            end
        end
    end
    sqfilter = sqfilter - mean(sqfilter(:));
    sqfilter = sqfilter ./ sqrt(sum(sqfilter(:) .^ 2));
end