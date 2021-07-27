% Eli Bowen
% converts the output of AudioFeatTransform() to a nice pretty power spectrogram
% INPUTS:
%   spec - output of AudioFeatTransform()
%   powerHandling - either 'power' or 'real+imag'
%   mode - mode used in AudioFeatTransform()
function [spec] = AudioCalculateSpectrogramFromFeats (spec, powerHandling, mode)
    validateattributes(spec, {'numeric'}, {'nonempty'});
    validateattributes(powerHandling, {'char'}, {'nonempty'});
    validateattributes(mode, {'char'}, {'nonempty'});
    
    if strcmp(mode, 'dft')
        spectrogram_power = Convert2PowerPhase(spec);
        if strcmp(powerHandling, 'real+imag')
            spec = [real(spec),imag(spec)];
            spec = sign(spec) .* log10(1 + abs(spec));
        else
            spec = log10(1+spectrogram_power);
        end
    elseif strcmp(mode, 'stft') % FFT
        spec = Convert2PowerPhase(spec);
        % method used by the "ams" library, produces cleaner spectrograms than version 1
        if strcmp(powerHandling, 'real+imag')
            error('I haven''t bothered implementing this yet');
        else
            spec = Magnitude2DB(spec);
        end
    elseif strcmp(mode, 'gammatone')
        warning('dunno what to do here yet');
    elseif strcmp(mode, 'gammatonegram')
        if strcmp(powerHandling, 'real+imag')
            error('I haven''t bothered implementing this yet');
        else
            spec = Magnitude2DB(spec);
        end
    elseif strcmp(mode, 'gammatonegramstftcenterfreqs')
        if strcmp(powerHandling, 'real+imag')
            error('I haven''t bothered implementing this yet');
        else
            spec = Magnitude2DB(spec);
        end
	elseif strcmp(mode, 'constantq')
        spec = Convert2PowerPhase(spec);
        if strcmp(powerHandling, 'real+imag')
            error('I haven''t bothered implementing this yet');
        else
            spec = Magnitude2DB(spec);
        end
    elseif strcmp(mode, 'melspec') % mel filtered spectrogram
        if strcmp(powerHandling, 'real+imag')
            error('I haven''t bothered implementing this yet');
        else
            spec = Magnitude2DB(spec);
        end
    elseif strcmp(mode, 'mfcc')
        % do nothing - we're already good
    elseif strcmp(mode, 'plpfilteredspec') % PLP filtered spectrogram
        % do nothing - we're already good
    elseif strcmp(mode, 'plpfeats') % PLP features
        % do nothing - we're already good
    elseif strcmp(mode, 'rastaplpfilteredspec') % RASTA-PLP filtered spectrogram
        % do nothing - we're already good
    elseif strcmp(mode, 'rastaplpfeats') % RASTA-PLP features
        % do nothing - we're already good
    else
        error('invalid mode');
    end
end


function [spec] = Magnitude2DB (spec)
    Smin = -59; % lower normalized dynamic range limit 
    Smax = -1;  % upper normalized dynamic range limit
    
    spec = spec ./ max(max(spec)); % normalize magntide spectrum
    spec = 20 .* log10(spec); % compute power spectrum in dB
    spec(spec>Smax) = Smax;
    spec(spec<Smin) = Smin;
    spec = spec - Smin;
end
