% Eli Bowen
% 2/6/2018
% INPUTS:
%   data - audio PCM samples
%   Fs - sampling rate of the audio
%   mode - char - type of features
%   stepSz
% RETURNS:
%   data
function [data] = AudioFeatTransform (data, Fs, mode, stepSz)
    validateattributes(data, {'numeric'}, {'nonempty'});
    validateattributes(Fs, {'numeric'}, {'nonempty','scalar','positive','integer'});
    validateattributes(mode, {'char'}, {'nonempty'});
    validateattributes(stepSz, {'numeric'}, {'nonempty','scalar','positive','integer'});
    assert(isvector(data));
    assert(Fs == 32000, 'All audio must be preprocessed to 32 KHz');

    windowSz = stepSz;
    if ~strcmp(mode, 'dft') && ~strcmp(mode, 'stft')
        windowSz = 2 * stepSz;
    end

    expectedSpecSize = ceil(numel(data) / stepSz);
    if mod(numel(data), stepSz) == 0
        data = [zeros(windowSz/2, 1);data(:);zeros(windowSz/2, 1)];
    else
        data = [zeros(windowSz/2, 1);data(:);zeros(stepSz-mod(numel(data), stepSz), 1);zeros(windowSz/2, 1)]; %pad with zeros at the end to a multiple of stepSize
    end

    if strcmp(mode, 'dft')
        assert(stepSz == 1024);
        data = BulkDFT(data); % in MatlabClusterNetwork
    elseif strcmp(mode, 'stft') % FFT
        data = stft(data, windowSz, stepSz)';
        data = data(:,1:(windowSz/4));
    elseif strcmp(mode, 'gammatone')
        nFreqs = windowSz / 8;
        cfs = iosr.auditory.makeErbCFs(round(Fs/windowSz), 8000, nFreqs);
        data = iosr.auditory.gammatoneFast(data, cfs, Fs);
        data = data(1:stepSz:end,:);
        error('TODO: size(data, 1) is too big sometimes');
    elseif strcmp(mode, 'gammatonegram')
        nFreqs = windowSz / 8;
        [data,cfs] = gammatonegram(data, Fs, windowSz/Fs, stepSz/Fs, nFreqs, round(Fs/windowSz), Fs/2, 0);
        data = data';
        data(:,cfs>8000) = [];
    elseif strcmp(mode, 'gammatonegramstftcenterfreqs') % gammatonegram (stft center freqs)
        [data,~] = gammatonegram(data, Fs, windowSz/Fs, stepSz/Fs, round(8000:(-2*Fs/windowSz):Fs/windowSz), round(Fs/windowSz), Fs/2, 0);
        data = data';
	elseif strcmp(mode, 'constantq')
        Q = 13;
        [data,~,~] = iir_cqt_spectrogram(data, windowSz, stepSz, Fs, Q);
        data = data';
        data = data(:,1:2:windowSz/4);
        error('TODO: size(data, 1) is too big sometimes');
    elseif strcmp(mode, 'melspec') % mel filtered spectrogram
        nFreqs = windowSz / 8;
        alpha = 0.97;              % preemphasis coefficient
        C = 24;                    % number of cepstral coefficients
        L = 22;                    % cepstral sine lifter parameter
        LF = round(Fs / windowSz); % lower frequency limit (Hz)
        HF = 8000;                 % upper frequency limit (Hz)
        [~,data,~,~] = mfcc(data, Fs, windowSz/Fs * 1000, stepSz/Fs * 1000, alpha, @hamming, [LF HF], nFreqs, C+1, L);
        data = flipud(data)';
    elseif strcmp(mode, 'mfcc')
        % library 1 (https://labrosa.ee.columbia.edu/matlab/rastamat/)
        data = MFCC(data, Fs, windowSz, stepSz);
        
        % library 2
%         Tw = windowSize/Fs * 1000; % analysis frame duration (ms)
%         Ts = stepSize/Fs * 1000;   % analysis frame shift (ms)
%         alpha = 0.97;              % preemphasis coefficient
%         C = 12;                    % number of cepstral coefficients
%         L = 22;                    % cepstral sine lifter parameter
%         LF = 32;                   % lower frequency limit (Hz)
%         HF = 8000;                 % upper frequency limit (Hz)
%         [spec,~,~] = mfcc(data, Fs, Tw, Ts, alpha, @hamming, [LF HF], 40, C+1, L);
%         spec = spec';
        
        % a third, unused library is available at https://engineering.purdue.edu/~malcolm/interval/1998-010/
    elseif strcmp(mode, 'plpfilteredspec') % PLP filtered spectrogram
        [~,data] = rastaplp(data, Fs, 0, 12, windowSz/Fs, stepSz/Fs); % calculate 12th order PLP features without RASTA
        data = data';
        %"Notice the greater level of temporal detail compared to the RASTA-filtered version"
        %"There is also greater spectral detail because our PLP model order is larger than the default of 8"
    elseif strcmp(mode, 'plpfeats') % PLP features
        [data,~] = rastaplp(data, Fs, 0, 12, windowSz/Fs, stepSz/Fs); % calculate 12th order PLP features without RASTA
        del = deltas(data);
        ddel = deltas(deltas(data,5),5); % double deltas are deltas applied twice with a shorter window
        data = [data;del;ddel]; %Composite, 39-element feature vector, just like we use for speech recognition
        data = data';
        % "Notice the greater level of temporal detail compared to the RASTA-filtered version"
        % "There is also greater spectral detail because our PLP model order is larger than the default of 8"
    elseif strcmp(mode, 'rastaplpfilteredspec') % RASTA-PLP filtered spectrogram
        [~,data] = rastaplp(data, Fs, 1, 12, windowSz/Fs, stepSz/Fs); % calculate basic RASTA-PLP cepstra and spectra
        data = data';
        % "Notice the auditory warping of the frequency axis to give more space to low frequencies and the way that RASTA filtering emphasizes the onsets of static sounds like vowels"
    elseif strcmp(mode, 'rastaplpfeats') % RASTA-PLP features
        [data,~] = rastaplp(data, Fs, 1, 12, windowSz/Fs, stepSz/Fs); % calculate basic RASTA-PLP cepstra and spectra
        del = deltas(data);
        ddel = deltas(deltas(data,5),5); % double deltas are deltas applied twice with a shorter window
        data = [data;del;ddel]; %Composite, 39-element feature vector, just like we use for speech recognition
        data = data';
        % "Notice the auditory warping of the frequency axis to give more space to low frequencies and the way that RASTA filtering emphasizes the onsets of static sounds like vowels"
    else
        error('invalid mode');
    end
    
    data = data(1:end-1,:); % with the padding we added at the top of this function, we have one too many timepoints
    assert(size(data, 1) == expectedSpecSize);
end
