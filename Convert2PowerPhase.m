% Eli Bowen
% 11/14/16
% converts a spectrogram, in imaginary numbers, into real valued power and phase
% INPUTS:
%   realAndImag - complex number T x #freqs
function [power,phase] = Convert2PowerPhase (realAndImag)
    power = abs(realAndImag); % "complex magnitude" sqrt(real(realAndImag).^2 + imag(realAndImag).^2)
    if nargout > 1
        phase = angle(realAndImag);
    end
end