% Eli Bowen 10/2016
% matlab's fft() and ifft() are total crap. unusable. here's an alternative.
% performs DFT on a PCM signal of arbitrary length, whereas DFT() only processes 1024-length timeseries data
% note: spectrogram may be slightly shorter than the input, since we only process time signals in multiples of 1024.
% INPUTS
%   y      - time series (PCM) data
%   stepSz - scalar (int-valued numeric) step size through PCM data, equal to window size
% RETURNS
%   y - numel(y)/1024 x 256 complex spectrogram; top frequencies were clipped, but no other modifications to the DFT were performed
function y = BulkDFT(y, stepSz)
    validateattributes(y, {'numeric'}, {}, 1);
    validateattributes(stepSz, {'numeric'}, {'nonempty','scalar','positive','integer'}, 2);
    assert(mod(stepSz, 2) == 0); % required for some of the math below

    assert(stepSz == 1024); % TEMP: would need work to support alternate stepSz values

    [cosLookup,sinLookup] = BuildCosSinLookupTable(cast(stepSz, 'like', y));

    n_windows = floor(numel(y) / stepSz);

    re = zeros(stepSz/2 + 1, n_windows, 'like', y);
    im = zeros(stepSz/2 + 1, n_windows, 'like', y);
    if isempty(gcp('nocreate')) % no parallel pool
        for j = 1 : n_windows
            yChunk = y(stepSz*(j-1)+1:stepSz*j);
            for f = 1 : stepSz/2 + 1
                re(f,j) = sum(yChunk .* cosLookup(:,f));
                im(f,j) = sum(yChunk .* sinLookup(:,f));
            end
        end
    else
        yChunks = zeros(stepSz, n_windows, 'like', y);
        for j = 1 : n_windows
            yChunks(:,j) = y(stepSz*(j-1)+1:stepSz*j);
        end
        parfor j = 1 : n_windows
            for f = 1 : stepSz/2 + 1
                re(f,j) = sum(yChunks(:,j) .* cosLookup(:,f));
                im(f,j) = sum(yChunks(:,j) .* sinLookup(:,f));
            end
        end
    end

    re = re(1:stepSz/4,:)';
    im = im(1:stepSz/4,:)';

    y = complex(re, im);
end


function [cosLookup,sinLookup] = BuildCosSinLookupTable(stepSz)
    cosLookup = zeros(stepSz, stepSz/2 + 1, 'like', stepSz);
    sinLookup = zeros(stepSz, stepSz/2 + 1, 'like', stepSz);
    twoPiN = 2 * pi / stepSz; % efficiency
    for t = 0 : stepSz-1
        for f = 0 : stepSz/2
            cosLookup(t+1,f+1) = cos(f * t * twoPiN);
            sinLookup(t+1,f+1) = -sin(f * t * twoPiN);
        end
    end
end