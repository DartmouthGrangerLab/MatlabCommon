%INPUTS:
% 	FS is the sampling frequency (Hz)
% 	TW is the analysis frame duration (ms) 
%	R is the frequency range (Hz) for filterbank analysis
%	M is the number of filterbank channels
%Eli Bowen 2/9/2018
function [cf] = mfcc_getcenterfreqs (fs, Tw, R, M)
    %% PRELIMINARIES 
    Nw = round(1E-3*Tw*fs); %frame duration (samples)
    
    nfft = 2^nextpow2(Nw); %length of FFT analysis 
    K = nfft/2+1;          %length of the unique part of the FFT 

    %% HANDY INLINE FUNCTION HANDLES
    % Forward and backward mel frequency warping (see Eq. (5.13) on p.76 of [1]) 
    % Note that base 10 is used in [1], while base e is used here and in HTK code
    hz2mel = @( hz )( 1127*log(1+hz/700) );     % Hertz to mel warping function
    mel2hz = @( mel )( 700*exp(mel/1127)-700 ); % mel to Hertz warping function

    [~,~,cf] = trifbank(M, K, R, fs, hz2mel, mel2hz); % Triangular filterbank with uniformly spaced filters on mel scale (size of H is M x K)
    cf = cf(2:end-1);
end


function [H,f,c] = trifbank (M, K, R, fs, h2w, w2h)
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
    assert(nargin == 6); % very lite input validation

    f_min = 0;          % filter coefficients start at this frequency (Hz)
    f_low = R(1);       % lower cutoff frequency (Hz) for the filterbank 
    f_high = R(2);      % upper cutoff frequency (Hz) for the filterbank 
    f_max = 0.5*fs;     % filter coefficients end at this frequency (Hz)
    f = linspace( f_min, f_max, K ); % frequency range (Hz), size 1xK
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
