% Eli Bowen 2/6/2018
% INPUTS:
%   data        - audio PCM samples
%   sr          - scalar (int-valued numeric) sampling rate of the audio
%   mode        - char - type of features
%   stepSz      - scalar (int-valued numeric)
%   complexMode - char - OPTIONAL - method for handling complex-valued outputs - one of 'raw', 'power', 'real+imag' (default = 'raw')
% RETURNS:
%   data
%   freqHz - frequency, in hz, of each output filter
function [data,freqHz] = AudioFeatTransform(data, sr, mode, stepSz, complexMode)
    validateattributes(data,   'numeric', {'nonempty'});
    validateattributes(sr,     'numeric', {'nonempty','scalar','positive','integer'});
    validateattributes(mode,   'char',    {'nonempty'});
    validateattributes(stepSz, 'numeric', {'nonempty','scalar','positive','integer'});
    assert(isvector(data));
    if ~exist('complexMode', 'var') || isempty(complexMode)
        complexMode = 'raw';
    end
    assert(strcmp(complexMode, 'raw') || strcmp(complexMode, 'real+imag') || strcmp(complexMode, 'power'));

    assert(sr >= 8000);

    windowSz = stepSz;
    if ~strcmp(mode, 'dft') && ~strcmp(mode, 'stft')
        windowSz = 2 * stepSz;
    end

    expectedSpecSz = ceil(numel(data) / stepSz);
    if mod(numel(data), stepSz) == 0
        data = [zeros(windowSz/2, 1);data(:);zeros(windowSz/2, 1)];
    else
        data = [zeros(windowSz/2, 1);data(:);zeros(stepSz-mod(numel(data), stepSz), 1);zeros(windowSz/2, 1)]; %pad with zeros at the end to a multiple of stepSize
    end

    if strcmp(mode, 'dft') % DFT (in aud_dft)
        data = BulkDFT(data, stepSz);
        freqStep = sr / windowSz; % in Hz (e.g. 31.25)
        freqHz = (1:1:windowSz/4) .* freqStep;
        if strcmp(complexMode, 'real+imag')
            data = [real(data),imag(data)];
            data = sign(data) .* log10(1 + abs(data));
        elseif strcmp(complexMode, 'power')
            data = log10(1 + Convert2PowerPhase(data));
        end
    elseif strcmp(mode, 'stft') % FFT
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        data = STFT(data, windowSz, stepSz)';
        data = data(:,1:(windowSz/4));
        freqStep = sr / windowSz; % in Hz (e.g. 31.25)
        freqHz = (1:1:windowSz/4) * freqStep;
        if strcmp(complexMode, 'real+imag')
            error('I haven''t bothered implementing this yet');
        elseif strcmp(complexMode, 'power')
            data = AudioMagnitude2Decibels(Convert2PowerPhase(data));
        end
    elseif strcmp(mode, 'gammatone')
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        nFreqs = windowSz / 8;
        freqHz = iosr.auditory.makeErbCFs(round(sr/windowSz), 8000, nFreqs);
        data = iosr.auditory.gammatoneFast(data, freqHz, sr);
        data = data(1:stepSz:end,:);
        error('TODO: size(data, 1) is too big sometimes');
        if strcmp(complexMode, 'real+imag') || strcmp(complexMode, 'power')
            error('I haven''t bothered implementing this yet');
        end
    elseif strcmp(mode, 'gammatonegram')
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        nFreqs = windowSz / 8;
        [data,cfs] = gammatonegram(data, sr, windowSz/sr, stepSz/sr, nFreqs, round(sr/windowSz), sr/2, 0);
        data = data';
        data(:,cfs>8000) = [];
        [~,freqHz] = MakeERBFilters(sr, nFreqs, round(sr/windowSz));
        freqHz(freqHz>8000) = [];
        freqHz = freqHz(end:-1:1);
        if strcmp(complexMode, 'real+imag')
            error('I haven''t bothered implementing this yet');
        elseif strcmp(complexMode, 'power')
            data = AudioMagnitude2Decibels(data);
        end
    elseif strcmp(mode, 'gammatonegramstftcenterfreqs') % gammatonegram (stft center freqs)
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        [data,~] = gammatonegram(data, sr, windowSz/sr, stepSz/sr, round(8000:(-2*sr/windowSz):sr/windowSz), round(sr/windowSz), sr/2, 0);
        data = data';
        freqStep = sr / windowSz; % in Hz (e.g. 31.25)
        freqHz = (1:2:windowSz/4) * freqStep;
        if strcmp(complexMode, 'real+imag')
            error('I haven''t bothered implementing this yet');
        elseif strcmp(complexMode, 'power')
            data = AudioMagnitude2Decibels(data);
        end
	elseif strcmp(mode, 'constantq')
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        Q = 13;
        [data,~,~] = iir_cqt_spectrogram(data, windowSz, stepSz, sr, Q);
        data = data';
        data = data(:,1:2:windowSz/4);
        error('TODO: size(data, 1) is too big sometimes');
        freqHz = (0:1:windowSz/2-1) * sr / windowSz;
        freqHz = freqHz(1:2:windowSz/4);
        if strcmp(complexMode, 'real+imag')
            error('I haven''t bothered implementing this yet');
        elseif strcmp(complexMode, 'power')
            data = AudioMagnitude2Decibels(Convert2PowerPhase(data));
        end
    elseif strcmp(mode, 'melspec') % mel filtered spectrogram
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        nFreqs = windowSz / 8;
        alpha = 0.97;              % preemphasis coefficient
        C = 24;                    % number of cepstral coefficients
        L = 22;                    % cepstral sine lifter parameter
        LF = round(sr / windowSz); % lower frequency limit (Hz)
        HF = 8000;                 % upper frequency limit (Hz)
        [~,data,~,~] = mfcc(data, sr, windowSz/sr * 1000, stepSz/sr * 1000, alpha, @hamming, [LF HF], nFreqs, C+1, L);
        data = flipud(data)';
        freqHz = mfcc_getcenterfreqs(sr, windowSz/sr * 1000, [LF,HF], nFreqs);
        if strcmp(complexMode, 'real+imag')
            error('I haven''t bothered implementing this yet');
        elseif strcmp(complexMode, 'power')
            data = AudioMagnitude2Decibels(data);
        end
    elseif strcmp(mode, 'mfcc')
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        % library 1 (https://labrosa.ee.columbia.edu/matlab/rastamat/)
        data = MFCC(data, sr, windowSz, stepSz);

        % library 2
%         Tw = windowSz/sr * 1000; % analysis frame duration (ms)
%         Ts = stepSz/sr * 1000;   % analysis frame shift (ms)
%         alpha = 0.97;            % preemphasis coefficient
%         C = 12;                  % number of cepstral coefficients
%         L = 22;                  % cepstral sine lifter parameter
%         LF = 32;                 % lower frequency limit (Hz)
%         HF = 8000;               % upper frequency limit (Hz)
%         [spec,~,~] = mfcc(data, sr, Tw, Ts, alpha, @hamming, [LF HF], 40, C+1, L);
%         spec = spec';

        % a third, unused library is available at https://engineering.purdue.edu/~malcolm/interval/1998-010/

        freqHz = 1:60;
        if strcmp(complexMode, 'real+imag') || strcmp(complexMode, 'power')
            % do nothing - raw data isn't complex
        end
    elseif strcmp(mode, 'plpfilteredspec') % PLP filtered spectrogram
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        [~,data] = rastaplp(data, sr, 0, 12, windowSz/sr, stepSz/sr); % calculate 12th order PLP features without RASTA
        data = data';
        % "Notice the greater level of temporal detail compared to the RASTA-filtered version"
        % "There is also greater spectral detail because our PLP model order is larger than the default of 8"
        freqHz = 1:ceil(hz2bark(sr/2)) + 1;
        if strcmp(complexMode, 'real+imag') || strcmp(complexMode, 'power')
            % do nothing - raw data isn't complex
        end
    elseif strcmp(mode, 'plpfeats') % PLP features
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        [data,~] = rastaplp(data, sr, 0, 12, windowSz/sr, stepSz/sr); % calculate 12th order PLP features without RASTA
        del = deltas(data);
        ddel = deltas(deltas(data,5),5); % double deltas are deltas applied twice with a shorter window
        data = [data;del;ddel]; % composite, 39-element feature vector, just like we use for speech recognition
        data = data';
        % "Notice the greater level of temporal detail compared to the RASTA-filtered version"
        % "There is also greater spectral detail because our PLP model order is larger than the default of 8"
        freqHz = 1:39;
        if strcmp(complexMode, 'real+imag') || strcmp(complexMode, 'power')
            % do nothing - raw data isn't complex
        end
    elseif strcmp(mode, 'rastaplpfilteredspec') % RASTA-PLP filtered spectrogram
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        [~,data] = rastaplp(data, sr, 1, 12, windowSz/sr, stepSz/sr); % calculate basic RASTA-PLP cepstra and spectra
        data = data';
        % "Notice the auditory warping of the frequency axis to give more space to low frequencies and the way that RASTA filtering emphasizes the onsets of static sounds like vowels"
        freqHz = 1:ceil(hz2bark(sr/2)) + 1;
        if strcmp(complexMode, 'real+imag') || strcmp(complexMode, 'power')
            % do nothing - raw data isn't complex
        end
    elseif strcmp(mode, 'rastaplpfeats') % RASTA-PLP features
        assert(sr == 32000, 'all audio must be preprocessed to 32 KHz'); % temporarily - lots of debugging to do for variable hz
        [data,~] = rastaplp(data, sr, 1, 12, windowSz/sr, stepSz/sr); % calculate basic RASTA-PLP cepstra and spectra
        del = deltas(data);
        ddel = deltas(deltas(data,5),5); % double deltas are deltas applied twice with a shorter window
        data = [data;del;ddel]; % composite, 39-element feature vector, just like we use for speech recognition
        data = data';
        % "Notice the auditory warping of the frequency axis to give more space to low frequencies and the way that RASTA filtering emphasizes the onsets of static sounds like vowels"
        freqHz = 1:39;
        if strcmp(complexMode, 'real+imag') || strcmp(complexMode, 'power')
            % do nothing - raw data isn't complex
        end
    else
        error('invalid mode');
    end
    
    data = data(1:end-1,:); % with the padding we added at the top of this function, we have one too many timepoints
    assert(size(data, 1) == expectedSpecSz);
end