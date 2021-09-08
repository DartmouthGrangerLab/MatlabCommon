% Short-Time Fourier Transform for single channel signals
% Jonathan Le Roux
% Inputs:
%  x            data vector (nsamples x 1)
%  flength      frame length 
%  fshift       frame shift 
%  w            analysis window function (default: sqrt(hanning))
% Output:
%  spec         STFT spectrogram (nbin x nframes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Copyright (C) 2008-2017 Jonathan Le Roux
%   Apache 2.0  (http://www.apache.org/licenses/LICENSE-2.0) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% made more efficient by Eli Bowen 9.19.2017, made capitalized so as not to conflict with matlab's stft()
function [x] = STFT (x, flength, fshift, w)
    assert(mod(flength, 2) ~= 1, 'odd ffts not implemented');
    if size(x, 2) > size(x, 1)
        x = x'; % ensure this is a row vector
    end
    if nargin < 3
       fshift = flength / 2; 
    end

    Q = flength / fshift;
    T = numel(x);
    M = ceil((T-flength) / fshift) + 1;

    if (M-1)*fshift + flength - T ~= 0
        x = cat(1, x, zeros((M-1)*fshift+flength-T, 1)); % make sure we have an entire frame at the end
    end

    if nargin < 4
        w = sqrt((0.5 - 0.5*cos(2*pi*(1:2:2*flength-1)'/(2*flength))) / Q * 2);
    else
        if size(w, 2) > 1
            w = w';
        end
        assert(length(w) == flength, 'The size of the specified window must be correct');
    end

    spec = zeros(flength, M, 'like', complex(1));
%     spec = zeros(flength/2+1, M);
%     [cosLookup,sinLookup] = BuildCosSinLookupTable(flength);

    % all of the below approaches yield identical results. The question is just which is faster on a given system.
%     if fshift == flength
%         x_chunked = zeros(floor(numel(x)/flength), flength);
%         for m = 1:M
%             x_chunked(m,:) = x((1:flength)+(m-1)*flength);
%         end
%         parfor m = 1:M
%             frame = bsxfun(@times, x_chunked(m,:)', w);
% %             [re,im] = DFT(frame, cosLookup, sinLookup);
% %             spec(:,m) = complex(re, im);
%             spec(:,m) = fft(frame); % we use the same normalization as matlab, i.e. 1/T in ifft only
%         end
%     else
    sampleStash = 1:flength;
    for m = 1:M
        spec(:,m) = fft(bsxfun(@times, x(sampleStash+(m-1)*fshift), w)); % we use the same normalization as matlab, i.e. 1/T in ifft only
%         frame = bsxfun(@times, x((1:flength)+(m-1)*fshift), w);
%         [re,im] = DFT(frame, cosLookup, sinLookup);
%         spec(:,m) = complex(re, im);
    end
%     end

    x = spec(1:(flength/2+1),:); % for memory efficiency, we use input variable as output variable
end