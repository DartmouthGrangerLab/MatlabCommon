% [Y,F] = gammatonegram(X, SR, TIMEWINDOW, STRIDE, N, FMIN, FMAX, USEFFT, WIDTH)
%    Calculate a spectrogram-like time frequency magnitude array based on Gammatone subband filters.
%INPUTS:
%   Waveform X (at sample rate SR) is passed through an
%   N (default 64) channel gammatone auditory model filterbank,
%   with lowest frequency FMIN (50)
%   and highest frequency FMAX (SR/2).
%   The outputs of each band then have their energy integrated over windows of TIMEWINDOW secs (0.025),
%   advancing by STRIDE secs (0.010) for successive columns.
%   These magnitudes are returned as an N-row nonnegative real matrix, Y.
%	If USEFFT is present and zero, revert to actual filtering and summing energy within windows.
%	WIDTH (default 1.0) is how to scale bandwidth of filters relative to ERB default (for fast method only).
%RETURNS:
%    F returns the center frequencies in Hz of each row of Y (uniformly spaced on a Bark scale).
%
% 2009-02-18 DAn Ellis dpwe@ee.columbia.edu
% Last updated: $Date: 2009/02/23 21:07:09 $
%downloaded by Eli Bowen 2/3/2018 and tweaked only for readability
function [X,cf] = gammatonegram (X, SR, TIMEWINDOW, STRIDE, numFreqs, FMIN, FMAX, USEFFT, WIDTH)
    if nargin < 2;  SR = 16000; end
    if nargin < 3;  TIMEWINDOW = 0.025; end
    if nargin < 4;  STRIDE = 0.010; end
    if nargin < 5;  numFreqs = 64; end
    if nargin < 6;  FMIN = 50; end
    if nargin < 7;  FMAX = SR/2; end
    if nargin < 8;  USEFFT = 1; end
    if nargin < 9;  WIDTH = 1.0; end
    
    windowType = 'hann'; %'hann' or 'rectangle'
    
    if USEFFT == 0
        % Use malcolm's function to filter into subbands (IGNORES FMAX)
        assert(FMAX==SR/2);
        
        if numel(numFreqs) == 1
            [fcoefs,cf] = MakeERBFilters(SR, numFreqs, FMIN);
        else
            [fcoefs,cf] = MakeERBFilters(SR, numFreqs, FMIN);
            numFreqs = numel(numFreqs);
        end
        
        XF = ERBFilterBank(X, flipud(fcoefs));
        
        nwin = round(TIMEWINDOW * SR);
        % Always use rectangular window for now
        %  if USEHANN == 1
%         window = hann(nwin)';
        %  else
        %    window = ones(1,nwin);
        %  end
        %  window = window/sum(window);
%         XF = [zeros(numFreqs, round(nwin/2)),XF.^2,zeros(numFreqs, round(nwin/2))];
        XF = XF.^2;
        
        hopsamps = round(STRIDE * SR);
        
        ncols = 1 + floor((size(XF, 2)-nwin) / hopsamps);
        
        X = zeros(numFreqs, ncols);
        if strcmp(windowType, 'rectangle')
            for i = 1:ncols
                X(:,i) = mean(XF(:,(i-1)*hopsamps + (1:nwin)), 2);
            end
        elseif strcmp(windowType, 'hann')
            window = hann(nwin)';
            winmx = repmat(window, numFreqs, 1);
            for i = 1:ncols
                X(:,i) = sum(winmx.*XF(:,(i-1)*hopsamps + (1:nwin)), 2);
            end
        end
        X = sqrt(X);
    else
        % USEFFT version
        % How long a window to use relative to the integration window requested
        winext = 1;
        twinmod = winext * TIMEWINDOW;
        % first spectrogram
        nfft = 2^(ceil(log(2*twinmod*SR)/log(2)));
        nhop = round(STRIDE*SR);
        nwin = round(twinmod*SR);
        [gtm,cf] = fft2gammatonemx(nfft, SR, numFreqs, WIDTH, FMIN, FMAX, nfft/2+1);
        % perform FFT and weighting in amplitude domain
        X = 1/nfft*gtm*abs(specgram(X, nfft, SR, nwin, nwin-nhop));
        % or the power domain?  doesn't match nearly as well
        %X = 1/nfft*sqrt(gtm*abs(specgram(X, nfft, SR, nwin, nwin-nhop).^2));
    end
end

    
