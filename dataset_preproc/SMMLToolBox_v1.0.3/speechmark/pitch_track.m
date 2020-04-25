%  Pitch-tracker (and est. of voicing power) from cepstral peaks & energy envelope of speech.
%  Syntax:
%  [pcont,tms,plocal,voicg,thr,deg_voicg,p0,specslope,degpsm] = ...
% 			pitch_track(SIGNAL,RATE,<PCT_THR>,<ADD_THR>,<NFFT>,<MAX_F0>,<FIGNO>)
%  where [] (or missing) may be used for the default of any arg., and:
% 	SIGNAL		= speech signal to be analyzed; see Note #3 for details;
% 	RATE		= sampling rate of 'SIGNAL' [dflt. = 16kHz];
% 	<PCT_THR>   = percentile of 'hvoicg' to use in setting threshold [dflt. = 40, 
% 				i.e., slightly < median, but see Notes] (may be fractional -- e.g., 50.3);
% 	<ADD_THR>   = offset (+ or -) on 'PCT_THR'-based threshold to set threshold for 'pcont', 
%                in dB [dflt. = 0];
% 	<NFFT>		= number of SIGNAL samples per FFT, for max. detectable period; 
%            	specify a negative number to multiply 'nonbreathy''s default value 
% 				by abs(that number); see Notes;
%    <MAX_F0> 	= [Hz] max. for any candidate (i.e., "sensible") fund. freq. F0 to be
% 				considered by 'nonbreathy' [dflt. = 400 Hz];
% 		-OR-
% 		<MAXMIN_F0> = [max., min.] values allowed for any candidate F0 [Hz]; see 
% 				'nonbreathy' for the default min. value;
% 	<FIGNO>		= figure number for plotting, or:
% 					0 for new figure;
% 					[] for no plotting;
% 				[dflt. = 0];
% 	pcont		= estimated pitch-period contour [in msec], with 0 wherever voicing 
%                is ~ as weak as noise (random signal), may be unreliable wherever weaker 
% 				than specified threshold; the value is an estimate of the local laryngeal 
% 				dynamics, not of the PERCEPT; also see Note 8;
% 	tms			= times (CENTERS of signal windows: COLUMN) at which pitch is estimated 
% 				[in SEC, normally in 8-msec steps], with start of first frame = 0; 
% 	plocal		= estimated local pitch-period [msec]: approx. = 'pcont' but defined 
% 				and > 0 throughout the signal, not just where the voicing is strong;
% 	hvoicg		= [row] measure of HARMONIC voicing ("non-breathiness") in dB, used for 
% 				'deg_voicg'; see Notes;
% 	thr			= scalar value [dB] actually used as the threshold for 'hvoicg' in computing 
% 				'pcont' from 'plocal';
% 	deg_voicg	= [row] measure of (fuzzy) degree of voicing (harm. & non-harm.) used 
% 				for 'pcont'; see Notes;
% 	p0			= each frame's log of mean power [dB];
% 	specslope = (a measure of) spectral slope [dB/octave] across the full frequency 
% 				range; generally positive in voiced regions (unless A is a high-order 
% 				derivative of the air-pressure signal);
% 	degpsm		= [row] degree to which smoothness of period and strong harmonics 
% 				indicate presence of (harmonic) voicing.
% 
%  Notes:
%  1.	The actual threshold used is given normally exactly by:
% 			thr = ADD_THR + "p", where "p" satisfies
% 				p = fractile(hvoicg,PCT_THR/100),
%        PROVIDED that this value of "p" is at least 1 dB lower than the 90th %ile of
%        'hvoicg'; otherwise this latter value is used instead.  However, 'thr'
%        will never be higher than a fixed value ~ 1, regardless of SIGNAL.  Thus, this
% 		function will detect (apparent) voicing aggressively in high-noise segments and
% 		should be followed by more cautious decisions (as in 'pitch_utt') if necessary.
%  2.	In most places (times), the pitch-period contour 'pcont' is equal to either 0 or 
% 		'plocal', with 0 at and near moments when 'deg_voicg' <~ 1/2 (esp. when 'hvoicg', 
% 		i.e., mean power within harmonics [dB], < 'thr').  Notice that both pitch-periods
% 		are measured in msec, NOT sec.
%  3.	Usage: 
% 			The voicing strength [dB] & spectrum (hence, cepstrum) are computed over 
% 		windows typical for normal human speech.  Frequencies above 4 kHz (or 3*MAX_F0,
%        whichever is higher) are attenuated, since vocal harmonics are almost always 
%        weak or non-existent above this, and other sounds are often prominent at 
%        higher frequencies.  If RATE > 16 kHz, this attenuation may not be sufficient;
%        in that case, it may be helpful to use 'downavg2(SIGNAL)' before calling this
%        function, and (if desired) 'backupsample(...,2,...)' for each of the 
%        output arg's.  
% 			It is often helpful to differentiate or pre-emphasize SIGNAL when calling 
% 		this function, to reduce very low-freq. "rumble" and 60-Hz contamination, and 
% 		to compensate for the spectral tilt of voiced speech -- for example, use 
% 		'pitch_track(diff(SIGNAL),...)', or at least 'pitch_track(hpfilt_std(SIGNAL),...)'.
% 			Values of RATE above twice the true highest freq's. of significant harmonics 
% 		(>~ 5-10 dB, typ.) will actually REDUCE the magnitude of 'hvoicg' (and of 
% 		'deg_voicg', usually).
%  4.	The strength of harm. voicing is taken from Hillenbrand's "non-breathiness"
% 		measure: see 'nonbreathy'.  In particular, white noise produces values
%        ~ (0.25+-.05), over a wide range of parameters, and good voicing generally 
% 		produces values ~ 3-5 times this level, or above.  (This threshold can be ~ 1 if
% 		NFFT is small, however.)  The measure is an average of power in the harmonics.
%  5.	The default value of NFFTfac scales inversely with MAX_F0, with the value -2
% 		when MAX_F0 has its default value.  This allows similar RELATIVE resolution 
% 		for the estimated pitch, regardless of the expected pitch range or maximum.
%  6.	In each window, the 'plocal' value is taken from the time at which the cepstral
% 		peak occurs, within the constraints (generous for a normal human adult) that are 
% 		used in 'nonbreathy' -- roughly, 1 to ~15+ msec, ~ 70 to 400 Hz (or MAXMIN_F0).  
% 		However, if SIGNAL might contain non-speech with periods to be detected, especially 
% 		lower periods than ~70 Hz, then use a larger value of NFFT (e.g., specify NFFT = 
% 		-3).  Beware that such low periods might introduce tracking of 60-Hz contamination,
% 		if present.
%  7.    'tms' are spaced at 8 msec (i.e., 0.008) if the signal is sampled at any 
%        multiple of 8 kHz OR at any rate >> 8 kHz (such as 44100 Hz).  Notice that
%        'tms' has units of seconds, but 'pcont' has units of milliseconds.
%  8.	'pcont' may be unreliable whereever the voicing is weak, i.e., degree << 1.  The
% 		(~fuzzy) degree of voicing is given by 'deg_voicg' or (especially for harmonic
% 		voicing) by 'degpsm'.  It may also be computed by 'deg_voiced(hvoicg,0)', or better:
% 			deg_voicedhnr_local(hvoicg,thr), or even
% 			deg_voiced(hvoicg,thr,tms,pcont,plocal,1000/MAX_F0, ...
% 						log10(envelope0(SIGNAL,round(RATE*.050))),[])
% 		or with some other 2nd arg. that is <~ 'thr'.  This is, in fact, approximately the
% 		computation behind 'degpsm'.  This may be a more reliable guide to 'pcont' values 
% 		than 'pcont>0' alone.  (However, this has NOT been established.)  Since 'pcont' 
% 		is the estimated acoustic period (except where voicing is very weak), it can be 
% 		useful to halve or double its value in certain places, as with 'pitch_halfdbl', to 
% 		produce a more realistic estimate of the PERCEPTUAL period.  This is especially true 
% 		if the degree of voicing is expected to use smoothness of pitch as one criterion, 
% 		as in 'deg_voicedhnr' and (in some cases) 'deg_voiced'.  However, intervals with 
% 		substantial numbers of halvings and doublings may be an indication of poorly 
% 		determined period (due to high noise, for example) OR to vocal anomalies; high
% 		power ('p0') at low frequencies can sometime be used to exclude noise as the cause (or,
% 		conversely, to identify noise as the cause and suppress the erroneous detection of 
% 		voicing).
%  9.	The regions (times) with 'hvoicg > 0' may often vary by ~20 msec, and occasionally
% 		up to ~50 msec, with variations in NFFT.  Similar or perhaps smaller variations may
% 		occur in 'deg_voicg > 0' as well.  (This has NOT been established.)
% 10.	The "frame rate", i.e., 1/the difference between successive values of 'tms', is 
% 		given by: 
% 			r = 125 Hz, 
% 		provided that RATE is any multiple of 1/32ms (such as 1000 Hz).
% 
%  See also: sgram, backupsample, downavg2, argmax, hist_unif, nonbreathy, fractile, 
% 	deg_voiced, pitch_halfdbl, deg_voicedhnr, deg_voicedhnr_local, hpfilt_std.
%
