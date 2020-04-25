% MFCC Mel frequency cepstral coefficient feature extraction.
%
%   MFCC(S,FS,TW,TS,ALPHA,WINDOW,R,M,N,L) returns mel frequency 
%   cepstral coefficients (MFCCs) computed from speech signal given 
%   in vector S and sampled at FS (Hz). The speech signal is first 
%   preemphasised using a first order FIR filter with preemphasis 
%   coefficient ALPHA. The preemphasised speech signal is subjected 
%   to the short-time Fourier transform analysis with frame durations 
%   of TW (ms), frame shifts of TS (ms) and analysis window function 
%   given as a function handle in WINDOW. This is followed by magnitude 
%   spectrum computation followed by filterbank design with M triangular 
%   filters uniformly spaced on the mel scale between lower and upper 
%   frequency limits given in R (Hz). The filterbank is applied to 
%   the magnitude spectrum values to produce filterbank energies (FBEs) 
%   (M per frame). Log-compressed FBEs are then decorrelated using the 
%   discrete cosine transform to produce cepstral coefficients. Final
%   step applies sinusoidal lifter to produce liftered MFCCs that 
%   closely match those produced by HTK [1].
%
%   [CC,FBE,FRAMES]=MFCC(...) also returns FBEs and windowed frames, with feature vectors and frames as columns.
%
%   This framework is based on Dan Ellis' rastamat routines [2]. The 
%   emphasis is placed on closely matching MFCCs produced by HTK [1]
%   (refer to p.337 of [1] for HTK's defaults) with simplicity and 
%   compactness as main considerations, but at a cost of reduced 
%   flexibility. This routine is meant to be easy to extend, and as 
%   a starting point for work with cepstral coefficients in MATLAB.
%   The triangular filterbank equations are given in [3].
%
%INPUTS:
%	S is the input speech signal (as vector)
% 	FS is the sampling frequency (Hz) 
% 	TW is the analysis frame duration (ms) 
%	TS is the analysis frame shift (ms)
%	ALPHA is the preemphasis coefficient
%	WINDOW is a analysis window function handle
%	R is the frequency range (Hz) for filterbank analysis
%	M is the number of filterbank channels
%	N is the number of cepstral coefficients (including the 0th coefficient)
%	L is the liftering parameter
%RETURNS:
%	CC is a matrix of mel frequency cepstral coefficients (MFCCs) with feature vectors as columns
%	FBE is a matrix of filterbank energies with feature vectors as columns
%	FRAMES is a matrix of windowed frames (one frame per column)
%
%   Example
%           Tw = 25;           % analysis frame duration (ms)
%           Ts = 10;           % analysis frame shift (ms)
%           alpha = 0.97;      % preemphasis coefficient
%           R = [ 300 3700 ];  % frequency range to consider
%           M = 20;            % number of filterbank channels 
%           C = 13;            % number of cepstral coefficients
%           L = 22;            % cepstral sine lifter parameter
%           % hamming window (see Eq. (5.2) on p.73 of [1])
%           hamming = @(N)(0.54-0.46*cos(2*pi*[0:N-1].'/(N-1)));
%           % Read speech samples, sampling rate and precision from file
%           [ speech, fs, nbits ] = wavread( 'sp10.wav' );
%           % Feature extraction (feature vectors as columns)
%           [ MFCCs, FBEs, frames ] = mfcc( speech, fs, Tw, Ts, alpha, hamming, R, M, C, L );
%           % Plot cepstrum over time
%           figure('Position', [30 100 800 200], 'PaperPositionMode', 'auto', 'color', 'w', 'PaperOrientation', 'landscape', 'Visible', 'on' ); 
%           imagesc( [1:size(MFCCs,2)], [0:C-1], MFCCs ); 
%           axis( 'xy' );
%           xlabel( 'Frame index' ); 
%           ylabel( 'Cepstrum index' );
%           title( 'Mel frequency cepstrum' );
%   References
%           [1] Young, S., Evermann, G., Gales, M., Hain, T., Kershaw, D., Liu, X., Moore, G., Odell, J., Ollason, D., Povey, D., Valtchev, V., Woodland, P., 2006. The HTK Book (for HTK Version 3.4.1). Engineering Department, Cambridge University.(see also: http://htk.eng.cam.ac.uk)
%           [2] Ellis, D., 2005. Reproducing the feature outputs of common programs using Matlab and melfcc.m. url: http://labrosa.ee.columbia.edu/matlab/rastamat/mfccs.html
%           [3] Huang, X., Acero, A., Hon, H., 2001. Spoken Language Processing: A guide to theory, algorithm, and system development. Prentice Hall, Upper Saddle River, NJ, USA (pp. 314-315).
%   Author: Kamil Wojcicki, September 2011
%downloaded by Eli Bowen 2/6/2018 from https://www.mathworks.com/matlabcentral/fileexchange/32849-htk-mfcc-matlab (and edited only for readability)
function [CC,FBE,frames,cf] = mfcc (speech, fs, Tw, Ts, alpha, window, R, M, N, L)
    %% PRELIMINARIES 
    assert(nargin == 10); % Ensure correct number of inputs

    % Explode samples to the range of 16 bit shorts
    if max(abs(speech)) <= 1
        speech = speech * 2^15;
    end

    Nw = round(1E-3*Tw*fs); %frame duration (samples)
    Ns = round(1E-3*Ts*fs); %frame shift (samples)

    nfft = 2^nextpow2(Nw); %length of FFT analysis 
    K = nfft/2+1;          %length of the unique part of the FFT 

    %% HANDY INLINE FUNCTION HANDLES
    % Forward and backward mel frequency warping (see Eq. (5.13) on p.76 of [1]) 
    % Note that base 10 is used in [1], while base e is used here and in HTK code
    hz2mel = @( hz )( 1127*log(1+hz/700) );     % Hertz to mel warping function
    mel2hz = @( mel )( 700*exp(mel/1127)-700 ); % mel to Hertz warping function

    dctm = @( N, M )( sqrt(2.0/M) * cos( repmat([0:N-1].',1,M) .* repmat(pi*([1:M]-0.5)/M,N,1) ) ); % Type III DCT matrix routine (see Eq. (5.14) on p.77 of [1])
    ceplifter = @( N, L )( 1+0.5*L*sin(pi*[0:N-1]/L) ); % Cepstral lifter routine (see Eq. (5.12) on p.75 of [1])

    %% SETUP
    [H,~,cf] = trifbank(M, K, R, fs, hz2mel, mel2hz); % Triangular filterbank with uniformly spaced filters on mel scale (size of H is M x K)
    cf = cf(2:end-1);
    
    %% FEATURE EXTRACTION 
    speech = filter([1 -alpha], 1, speech); % Preemphasis filtering (see Eq. (5.1) on p.73 of [1])
    frames = vec2frames(speech, Nw, Ns, 'cols', window, false); % Framing and windowing (frames as columns)
    MAG = abs(fft(frames, nfft, 1)); % Magnitude spectrum computation (as column vectors)
    FBE = H * MAG(1:K,:); % Filterbank application to unique part of the magnitude spectrum
    % FBE( FBE<1.0 ) = 1.0; % apply mel floor

    DCT = dctm(N, M); % DCT matrix computation
    CC = DCT * log(FBE); % Conversion of logFBEs to cepstral coefficients through DCT
    lifter = ceplifter(N, L); % Cepstral lifter computation
    CC = diag(lifter) * CC; % Cepstral liftering gives liftered cepstral coefficients (~ HTK's MFCCs)
end


% TRIFBANK Triangular filterbank.
%
%   [H,F,C]=TRIFBANK(M,K,R,FS,H2W,W2H) returns matrix of M triangular filters 
%   (one per row), each K coefficients long along with a K coefficient long 
%   frequency vector F and M+2 coefficient long cutoff frequency vector C. 
%   The triangular filters are between limits given in R (Hz) and are 
%   uniformly spaced on a warped scale defined by forward (H2W) and backward (W2H) warping functions.
%
%INPUTS:
%	M is the number of filters, i.e. number of rows of H
%	K is the length of frequency response of each filter i.e. number of columns of H
%	R is a two element vector that specifies frequency limits (Hz), i.e. R = [ low_frequency high_frequency ];
%	FS is the sampling frequency (Hz)
%	H2W is a Hertz scale to warped scale function handle
%	W2H is a wared scale to Hertz scale function handle
%RETURNS:
%	H is a M by K triangular filterbank matrix (one filter per row)
%	F is a frequency vector (Hz) of 1xK dimension
% 	C is a vector of filter cutoff frequencies (Hz), note that C(2:end) also represents filter center frequencies, and the dimension of C is 1x(M+2)
%   Reference
%           [1] Huang, X., Acero, A., Hon, H., 2001. Spoken Language Processing: A guide to theory, algorithm, and system development. Prentice Hall, Upper Saddle River, NJ, USA (pp. 314-315).
%   Author  Kamil Wojcicki, UTD, June 2011
%downloaded by Eli Bowen 2/6/2018 from https://www.mathworks.com/matlabcentral/fileexchange/32849-htk-mfcc-matlab (and edited only for readability)
function [H,f,c] = trifbank (M, K, R, fs, h2w, w2h)
    assert(nargin == 6); % very lite input validation

    f_min = 0;          % filter coefficients start at this frequency (Hz)
    f_low = R(1);       % lower cutoff frequency (Hz) for the filterbank 
    f_high = R(2);      % upper cutoff frequency (Hz) for the filterbank 
    f_max = 0.5*fs;     % filter coefficients end at this frequency (Hz)
    f = linspace(f_min, f_max, K); % frequency range (Hz), size 1xK
%     fw = h2w(f);

    % filter cutoff frequencies (Hz) for all filters, size 1x(M+2)
    c = w2h(h2w(f_low)+[0:M+1]*((h2w(f_high)-h2w(f_low))/(M+1)));
%     cw = h2w(c);

    H = zeros(M, K); %zero otherwise
    for m = 1:M 
        % implements Eq. (6.140) on page 314 of [1] 
        % k = f>=c(m)&f<=c(m+1); % up-slope
        % H(m,k) = 2*(f(k)-c(m)) / ((c(m+2)-c(m))*(c(m+1)-c(m)));
        % k = f>=c(m+1)&f<=c(m+2); % down-slope
        % H(m,k) = 2*(c(m+2)-f(k)) / ((c(m+2)-c(m))*(c(m+2)-c(m+1)));

        % implements Eq. (6.141) on page 315 of [1]
        k = f>=c(m)&f<=c(m+1); % up-slope
        H(m,k) = (f(k)-c(m))/(c(m+1)-c(m));
        k = f>=c(m+1)&f<=c(m+2); % down-slope
        H(m,k) = (c(m+2)-f(k))/(c(m+2)-c(m+1));
   end

   % H = H./repmat(max(H,[],2),1,K);  % normalize to unit height (inherently done)
   % H = H./repmat(trapz(f,H,2),1,K); % normalize to unit area 
end
