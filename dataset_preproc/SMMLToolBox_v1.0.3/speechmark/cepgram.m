%  Compute & optionally plot the "cepstrogram" of the specified signal.
% 		[b,td,t,noisefl,sgm] = cepgram(A,<NFFT>,<Fs>,<WINDOW>,<NOVERLAP>)
%  Input & first 3 output arguments are identical to 'sgram', EXCEPT that:
%  A.first output arg. is (a row of) columns of cepstra, instead of spectra; however,
% 	the first component (time delay = 0) contains the log of mean power [dB], rather 
% 	than the (generally meaningless) mean of the log of power.
%  B.2nd output arg. is converted to the approp. vector of time-delays (inverse freq's.).
%  C.2nd input arg. must NOT be a vector of freq's.  (The chirp-z and other
% 	special cases for 'sgram' are not implemented here.)
%  D.This function uses the conventions of 'sgram' (in particular, of 'sgram_args').  
% 	Note that all input & output arg's. of SPECGRAM are allowed by 'sgram', but 
% 	'sgram_args' provides different defaults, and it additionally permits NFFT, WINDOW, 
% 	and NOVERLAP to be specified more flexibly.
% 
%  In addition:
% 	mincol	= the minimum meaningful log-power across any column (i.e., frame or time slice) 
% 			of the spectrogram; this may be taken as the "noise floor" for each frame; 
% 			this value may or may not be realized in any frame, and it generally varies 
% 			somewhat from frame to frame; it represents a processing and data limit, not 
% 			necessarily the level of any undesired signals in A;
% 	sgm		= the log-spectrogram from which 'b' is computed; other than the mean value in
% 			each frame [see above concerning 'b(1,:)'], and duplication of negative
% 			freq's., this is identical to REAL(FFT(b)); values of 'sgm(:,k)' that are
% 			equal to or lower than 'mincol(k)' should be regarded as roundoff or
% 			meaningless.  NOTE: If, by any means (e.g., caching), 'b' is computed
% 			without computing a spectrogram explicitly, then 'sgm' will be EMPTY.
% 
% 	Each cepstrum (column) is computed from the corresponding spectrum (column) 
% 	of the spectrogram, and is measured in dB (i.e., uses '20*log10').  Typical
% 	max. values in well voiced segments of speech may be ~2-10 depending on the 
% 	number of harmonics within the freq. range (0 to Fs/2).  These values are indep. 
% 	of STD(A), and nearly indep. of NFFT (assuming NFFT is large enough 
% 	for the lowest periods found in A).
% 
%  Notes:
%  1.The cepstrum is always Real-valued (but may be < 0), if the signal is Real-valued.
%  2.The phase structure of each spectrum (column of spectrogram) is DISCARDED when
% 	computing each cepstrum.  (The result is sometimes called a "Real cepstrum".)
%  3.As with 'sgram', if no output arg's. are specified, the result will be 
% 	displayed in a figure, not returned.  What is displayed is MAX(0,b), not 'b'
% 	itself; this causes signals with only odd harmonics to produce a somewhat
% 	different figure from that of signals with both even and odd harmonics.
%  4.When displayed, the first 2 rows are omitted, because they often dominate
% 	the dynamic range (so the rest of the image is "flattened" in dyn. range).
% 	Note that the 1st row contains the log of the mean power for each slice.  The 
% 	2nd row contains the log of the magnitude of the slice's broadest spectral
% 	"envelope": the cosine that best fits the slice's log spectrum (both + & - 
%    frequencies -- for a Real signal, the spectrum is symmetric, so there
% 	is no sine term).
%  5.The numerical values are computed from the spectrogram by an inverse FFT,
% 	Thus, typical spectrogram contrasts of 20 dB [in power] between harmonic 
% 	and non-harmonic frequencies correspond to peak cepstral values ~20 dB, 
% 	PROVIDED that the harmonics (at this amplitude) cover the entire freq. range
% 	of 0 to Fs/2.  If they cover, e.g., 1/4 of this range, then the mean is reduced 
% 	to 5 dB (a frequent result in voiced speech). Therefore, it can be helpful to
% 	limit SIGNAL to a range (Fs/2) which corresponds to the strong harmonics, as with
% 	'lowpass2' or 'downavg2'.
%  6.When WINDOW and NOVERLAP are positive Integers (or converted into these according
% 	to the rules of 'sgram_args'), then the frame rate, i.e., the inverse of the 
% 	difference between successive values of 't', is given by:
% 		Fs / (WINDOW-NOVERLAP).
%  7.'b', 'mincol', and 'sgm' will be SINGLE if A is single-precision.  Since acoustic 
% 	signals typically have less than single precision (23 bits), this can save 50% of 
% 	memory.  The default is DOUBLE.
% 
%  See also: SPECGRAM, sgram, sgram_args, lowpass2, downavg2.
%
