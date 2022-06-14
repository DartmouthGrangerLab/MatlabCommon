% Eli Bowen
% converts a real (non-complex) spectrogram to decibels
% if your spectrogram is complex, call Convert2PowerPhase() first
% method used by the "ams" library, produces cleaner spectrograms than version 1
% INPUTS
%   spec - 2D (numeric) non-complex (real) spectrogram
% RETURNS
%   spec
function spec = AudioMagnitude2Decibels(spec)
    Smin = -59; % lower normalized dynamic range limit 
    Smax = -1;  % upper normalized dynamic range limit

    spec = spec ./ max(max(spec)); % normalize magntide spectrum
    spec = 20 .* log10(spec); % compute power spectrum in dB
    spec(spec>Smax) = Smax;
    spec(spec<Smin) = Smin;
    spec = spec - Smin;
end