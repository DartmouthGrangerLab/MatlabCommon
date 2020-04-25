%Eli Bowen
%2/6/2018
%INPUTS:
%   data - audio PCM samples
%   Fs - sampling rate of the audio
%   mode - char - type of features
%   stepSize
function [data] = AudioFeatTransform (data, Fs, mode, stepSize)
    validateattributes(data, {'numeric'}, {'nonempty'});
    validateattributes(Fs, {'numeric'}, {'nonempty','scalar','positive','integer'});
    validateattributes(mode, {'char'}, {'nonempty'});
    validateattributes(stepSize, {'numeric'}, {'nonempty','scalar','positive','integer'});
    assert(isvector(data));
    assert(Fs == 32000, 'All audio must be preprocessed to 32kHz');
    
    windowSize = stepSize;
    if ~strcmp(mode, 'dft') && ~strcmp(mode, 'stft')
        windowSize = 2 * stepSize;
    end
    
    expectedSpecSize = ceil(numel(data) / stepSize);
    if mod(numel(data), stepSize) == 0
        data = [zeros(windowSize/2, 1);data(:);zeros(windowSize/2, 1)];
    else
        data = [zeros(windowSize/2, 1);data(:);zeros(stepSize-mod(numel(data), stepSize), 1);zeros(windowSize/2, 1)]; %pad with zeros at the end to a multiple of stepSize
    end
    
    if strcmp(mode, 'dft')
        assert(stepSize == 1024);
        data = BulkDFT(data); %in MatlabClusterNetwork
    elseif strcmp(mode, 'stft') %FFT
        data = stft(data, windowSize, stepSize)';
        data = data(:,1:(windowSize/4));
    elseif strcmp(mode, 'gammatone')
        numFreqs = windowSize/8;
        cfs = iosr.auditory.makeErbCFs(round(Fs/windowSize), 8000, numFreqs);
        data = iosr.auditory.gammatoneFast(data, cfs, Fs);
        data = data(1:stepSize:end,:);
        error('TODO: size(data, 1) is too big sometimes');
    elseif strcmp(mode, 'gammatonegram')
        numFreqs = windowSize/8;
        [data,cfs] = gammatonegram(data, Fs, windowSize/Fs, stepSize/Fs, numFreqs, round(Fs/windowSize), Fs/2, 0);
        data = data';
        data(:,cfs>8000) = [];
    elseif strcmp(mode, 'gammatonegramstftcenterfreqs') %gammatonegram (stft center freqs)
        [data,~] = gammatonegram(data, Fs, windowSize/Fs, stepSize/Fs, round(8000:(-2*Fs/windowSize):Fs/windowSize), round(Fs/windowSize), Fs/2, 0);
        data = data';
	elseif strcmp(mode, 'constantq')
        Q = 13;
        [data,~,~] = iir_cqt_spectrogram(data, windowSize, stepSize, Fs, Q);
        data = data';
        data = data(:,1:2:windowSize/4);
        error('TODO: size(data, 1) is too big sometimes');
    elseif strcmp(mode, 'melspec') %mel filtered spectrogram
        numFreqs = windowSize / 8;
        alpha = 0.97;                %preemphasis coefficient
        C = 24;                      %number of cepstral coefficients
        L = 22;                      %cepstral sine lifter parameter
        LF = round(Fs / windowSize); %lower frequency limit (Hz)
        HF = 8000;                   %upper frequency limit (Hz)
        [~,data,~,~] = mfcc(data, Fs, windowSize/Fs * 1000, stepSize/Fs * 1000, alpha, @hamming, [LF HF], numFreqs, C+1, L);
        data = flipud(data)';
    elseif strcmp(mode, 'mfcc')
        %library 1
%         Tw = windowSize/Fs * 1000; %analysis frame duration (ms)
%         Ts = stepSize/Fs * 1000;   %analysis frame shift (ms)
%         alpha = 0.97;              %preemphasis coefficient
%         C = 12;                    %number of cepstral coefficients
%         L = 22;                    %cepstral sine lifter parameter
%         LF = 32;                   %lower frequency limit (Hz)
%         HF = 8000;                 %upper frequency limit (Hz)
%         [spec,~,~] = mfcc(data, Fs, Tw, Ts, alpha, @hamming, [LF HF], 40, C+1, L);
%         spec = spec';
        
        %library 2 (https://labrosa.ee.columbia.edu/matlab/rastamat/)
        data = MFCC(data, Fs, windowSize, stepSize);
        
        %a third, unused library is available at https://engineering.purdue.edu/~malcolm/interval/1998-010/
    elseif strcmp(mode, 'plpfilteredspec') %PLP filtered spectrogram
        [~,data] = rastaplp(data, Fs, 0, 12, windowSize/Fs, stepSize/Fs); %calculate 12th order PLP features without RASTA
        data = data';
        %"Notice the greater level of temporal detail compared to the RASTA-filtered version"
        %"There is also greater spectral detail because our PLP model order is larger than the default of 8"
    elseif strcmp(mode, 'plpfeats') %PLP features
        [data,~] = rastaplp(data, Fs, 0, 12, windowSize/Fs, stepSize/Fs); %calculate 12th order PLP features without RASTA
        del = deltas(data);
        ddel = deltas(deltas(data,5),5); %double deltas are deltas applied twice with a shorter window
        data = [data;del;ddel]; %Composite, 39-element feature vector, just like we use for speech recognition
        data = data';
        %"Notice the greater level of temporal detail compared to the RASTA-filtered version"
        %"There is also greater spectral detail because our PLP model order is larger than the default of 8"
    elseif strcmp(mode, 'rastaplpfilteredspec') %RASTA-PLP filtered spectrogram
        [~,data] = rastaplp(data, Fs, 1, 12, windowSize/Fs, stepSize/Fs); %calculate basic RASTA-PLP cepstra and spectra
        data = data';
        %"Notice the auditory warping of the frequency axis to give more space to low frequencies and the way that RASTA filtering emphasizes the onsets of static sounds like vowels"
    elseif strcmp(mode, 'rastaplpfeats') %RASTA-PLP features
        [data,~] = rastaplp(data, Fs, 1, 12, windowSize/Fs, stepSize/Fs); %calculate basic RASTA-PLP cepstra and spectra
        del = deltas(data);
        ddel = deltas(deltas(data,5),5); %double deltas are deltas applied twice with a shorter window
        data = [data;del;ddel]; %Composite, 39-element feature vector, just like we use for speech recognition
        data = data';
        %"Notice the auditory warping of the frequency axis to give more space to low frequencies and the way that RASTA filtering emphasizes the onsets of static sounds like vowels"
    else
        error('invalid mode');
    end
    
    data = data(1:end-1,:); %with the padding we added at the top of this function, we have one too many timepoints
    assert(size(data, 1) == expectedSpecSize);
end
