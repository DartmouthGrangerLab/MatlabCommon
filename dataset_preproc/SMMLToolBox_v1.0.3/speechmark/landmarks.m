%  The abrupt-landmark array of a speech-acoustic audio signal.
%  Syntax: [lms,tvals,pcont,env,envthr,voicg,vthr]  = landmarks(SIGNAL,<Fs>,<MAX_F0>,<DRAW>,<AGESZ>)
%    Returns a 3xN array of landmarks (+g/-g, +b/-b, etc), as in 'lm_codes',
%    for some N >= 0; each landmark is denoted by a time, type (code), and strength measure.
% 	If supplied, MAX_F0 = max. F0 to be considered (e.g., by 'pitch_utt') when
% 	determining voicing; 
% 		-OR-	the 2-vector [max. F0, min. F0] to be considered in determining voicing;
% 	if not specified, the min. F0 to be considered may scale with MAX_F0 (although this
% 	is implementation-dependent; a typical value might be approx. MAX_F0/5).
%  If DRAW [dflt. = false], draws a plot of the waveform and s/gram, showing the landmarks.
% 	If DRAW is neither False [same as empty] nor True, then the plot will be constructed
% 	and the value passed as the "BW" argument of 'lm_draw'.  Note that this may
% 	require that it be a string or have other restrictions.  This argument has NO
% 	effect on the landmark computations, only on the display of the result.
%  Asguments:
% 	SIGNAL 	= speech signal to be processed.
% 	<Fs>	= sampling rate of 'signal' [dflt = 16kHz].  Rates below 11kHz are likely to 
% 			produce unreliable landmarks (except voicing transitions); rates > 16kHz are 
% 			unlikely to be better than 16kHz.
% 	<AGESZ>	= age or size code [case-insens.; dflt. = "adult"] to set spectral bands and to
% 			effect high-pass filtering with 'hpfilt_std'; see Note 4.
% 	tvals	= times at which pitch is evaluated.
% 	pcont	= pitch track of 'signal', as returned by 'pitch_utt';
%    env		= amplitude-envelope of 'diff(SIGNAL)', smoothed over the SHORTEST intervals 
%            characteristic of speech (~ 10-20 msec); values within this distance
% 			of the ends of the signal are suspect (and are not plotted); see Note 6;
% 	envthr	= threshold of 'env' to identify intervals that are too quiet to be
% 			evaluated for voicing.
% 	voicg	= measure of voicing ("non-breathiness") used for 'pcont' [row; dB]; NOT 
% 			necessarily 0 wherever 'pcont' = 0, even though voicing is non-harmonic if 
% 			'pcont' = 0;
% 	vthr	= scalar value actually used as the threshold for 'voicg' in deciding if
% 			'pcont' should use the local estimate or be set to zero.
% 
%  Notes: 
%  1.After constructing the well formed landmark sequence, the function draws as in 'lm_draw'.
%  2.It is sometimes helpful to suppress near-silent ("quiet") intervals of SIGNAL by
% 	using 'nonquiet' or 'nonquiet_ctr' before calling this function.  However, such intervals
% 	are already suppressed here based on the envelope (as in 'deg_speechenv').
%  3.This function applies a high-pass filter before processing, to reduce rumble and
% 	attenuate 60 Hz and other low-frequency components.  However, the attenuation is
% 	modest; if 60-Hz contamination is likely, filter more strongly with (e.g.) 
% 		smooth(SIGNAL,kernel_no60_std(Fs))
% 	before calling this function.
%  4.If MAX_F0 is empty, both max. and min. F0 limits will be determined by 'maxf0_std' 
% 	from AGESZ according to the rules:
% 		a. If AGESZ = "adult", then the values of 'maxf0_std("n")'	-- i.e., adult, unspecified sex.
% 		b. Else if AGESZ = "child", then the values of 'maxf0_std("i")'	-- i.e., infant.
% 		c. Else the values of 'maxf0_std("")'.
% 	However, the converse does NOT hold: If AGESZ is absent or "", it will be interpreted as
% 	"adult", regardless of any value of MAX_F0.  If MAX_F0 and AGESZ are incompatible (e.g.,
% 	in falsetto: adult with very high F0), NO message will be provided.
% 	The value of AGESZ must be recognized by 'hpfilt_std' in all cases.
%  5.If drawing generates an error, the figure may be left blank.  However, this function will
% 	still return its appropriate outputs.  The figure can use substantial memory, so drawing
% 	might produce "Out of Memory" errors that would not otherwise affect processing.
%  6.'env' is smoothed over the shortest intervals characteristic of speech; for more
% 	typical intervals ~50-100 msec, simply smooth 'env' itself -- e.g., for 50 ms:
% 			'smooth(env,round(0.050*RATE))' or 'smooth(env,-1-2*round(0.025*RATE))'
%  7.This function attempts to detect speech-acoustic landmarks reliably, when SIGNAL 
% 	contains a speech-acoustic signal, possibly with some background noise.  It does NOT
% 	attempt to detect non-speech signals and avoid processing them.  If SIGNAL may contain
% 	non-quiet intervals of each, 'lm_sylfilter' may help to discard some 'lms' elements of 
% 	the non-speech intervals, and 'deg_speech' may help as well, after 'lms' is computed.
% 	If SIGNAL is not an audio signal (at least), the results will be unreliable.  See 
% 	'deg_audioarr_global', which should typically be used before this function except when
% 	SIGNAL can be guaranteed to be a well digitized version of the pressure waveform of an
% 	audio/acoustic signal.  I.e., no microphone problems, no recording errors, no
% 	too-faint audio signals or too-coarse analog/digital conversion, etc.
%  8.'pcont' and F0 values:
% 	'pcont' estimates the true period.  Because of the possibility of period-doubling
% 	(the "missing fundamental"), this may be twice the apparent period.  So if the minimum
% 	allowed value of F0 is supplied (as MAX_F0(2)), be sure to allow for this by reducing
% 	it by an extra factor of 2.
% 	Apart from period-doubling, F0 variation across an utterance is usually less than an 
% 	octave.  However, unless the talker or utterance is known, the variation across 
% 	talkers and utterances may exceed this.  In these cases, the upper limit (MAX_F0(1))
% 	should be slightly above the normal upper limit for a known talker and utterance.  
% 	('maxf0_std' returns a slightly high value, to account for this.)  Also, the lower 
% 	limit (MAX_F0(2), if this is specified) should be slightly more than an octave below
% 	the upper limit to account for the same variability, and a further octave below to 
% 	allow for period-doubling.  (Again, 'maxf0_std' accounts for this.)  This is the 
% 	reason that the default value of the lower limit is slightly more than 2 octaves below
% 	MAX_F0(1), instead of slightly more than a single octave below.
% 	Note that actual 'pcont' values determined here may occasionally fall slightly outside
% 	the specified limits.
%  9.A LM sequence is considered well formed if:
% 	(a) all landmarks are in increasing time-order, and
% 	(b) any coinciding largyngeal landmarks (+-p, +-g) are listed with +p following the
% 	coinciding +g, and -p preceding the coinciding -g.
% 
%  See also: vowel_lms, pitch_utt, lm_codes, nonquiet, nonquiet_ctr, lm_draw, kernel_no60_std,
% 	maxf0_std, deg_speechenv, hpfilt_std, smooth, deg_audioarr_global, deg_speech,
% 	lm_sylfilter.
%
