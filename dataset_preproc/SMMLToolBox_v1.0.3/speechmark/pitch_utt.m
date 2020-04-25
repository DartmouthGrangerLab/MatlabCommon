%  Pitch contour only within silence-separated utterances.
%  Syntax:
%    [pc,env,voicg,envthr,pcont,tms,vthr] = pitch_utt(SIGNAL,<RATE>,<ENVBASE>,<MAX_F0>)
%  where [] (or missing) may be used for the default of any arg., and:
% 	pc  		= estimated pitch-period contour [in msec], with 0 wherever voicing 
%                is weaker than specified threshold (otherwise 'pc' > 0), and suppressing
%                unreasonably short intervals of voicing transition (V->U->V, or opposite); 
% 				the value is an estimate of the local laryngeal dynamics, not of the 
% 				PERCEPT; also see Notes;
%    env         = amplitude-envelope of 'diff(SIGNAL)', smoothed over SHORTEST intervals 
%                characteristic of speech (~ 10-20 msec); the source is assumed silent
% 				for ~ 5 times this long beyond the ends of SIGNAL; shape = same as SIGNAL, 
% 				length = length(SIGNAL) - 1; for more typical speech intervals, see Note 7;
% 	voicg		= measure of voicing ("non-breathiness") used for 'pc' [row; dB]; NOT 
% 				necessarily 0 wherever 'pc' = 0, even though voicing is apparently absent 
%                if 'pc' = 0; see Notes;
% 	envthr		= scalar value used as the threshold for 'env' in computing "utterances",
% 				i.e., segments of SIGNAL where 'pc' is meaningful; see Notes;
%    pcont       = est'd. pitch-period contour [row; msec], with 0 where voicing is
%                weaker than a specified threshold;
%    tms       = times [col.; sec] at which 'pc', etc., are sampled;
% 	vthr		= scalar value actually used as the threshold for 'voicg' in deciding if
% 				'pcont' (and then 'pc') should use the local estimate or be set to zero;
%                see Notes;
% 	p0			= each frame's log of mean power [dB];
% 	specslope = (a measure of) spectral slope [dB/octave] across the full frequency 
% 				range; generally positive in voiced regions (unless A is a high-order 
% 				derivative of the air-pressure signal);
% 	deg_v		= [row] contour of fuzzy degree to which speech signal measures indicate 
% 				presence of voiced speech;
% 	deghv		= [row] contour of degree to which smoothness of period and strong 
% 				harmonics indicate presence of (harmonic) voicing;
% 	SIGNAL		= speech signal to be analyzed; see Note #3;
% 	<RATE>		= sampling rate of 'SIGNAL' [dflt. = 16kHz];
%    <ENVBASE>   = "base" level of log10(envelope of SIGNAL) [dflt = +Inf] to use in
%                decisions on presence/absence of ignorably small amplitude;
%    <MAX_F0> 	= [Hz] max. for any candidate (i.e., "sensible") fundamental freq. to be
% 				considered by 'pitch_track' [default taken from lower-level functions].
% 
%  Notes:
%  1.	The part of SIGNAL used for 'pc' is given exactly by:
% 			DIFF(SIGNAL).*(env>envthr).
%        Thus, LENGTH(env) = LENGTH(SIGNAL)-1, though 'pc*' and 'voicg' are typically
%        produced at a much lower rate (one value per "slice", ~ 125 Hz).
%  2.	All estimates are computed over windows typical for normal human speech.
%  3.    SIGNAL will be differentiated here, to compensate for spectral tilt of normal
%        voice; but any known noise components (e.g., low-freq. "rumble", or 60-Hz 
%        contamination) should be removed by filtering before calling this function.
%  4.    'pc*' and 'voicg' samples are spaced at 8 msec (i.e., 0.008) if the signal is 
%        sampled at any multiple of 8 kHz OR at any rate >> 8 kHz (such as 44100 Hz).  
%        In general,their sampling rate is 'RATE*(tms(2)-tms(1))'.  These 
%        lower-rate signals may be converted to SIGNAL's rate using 'backupsample'.  (A 
%        typical rate ratio is 128 = .008*16000, correct for 16kHz SIGNAL data.)
%  5.    'envthr' is computed from the actual envelope of SIGNAL, as
%        well as from ENVBASE if supplied.  If the actual envelope suggests
%        a higher threshold than ENVBASE, ENVBASE will be used instead.
%  6.    'pc' (and 'pcont', more rarely) may be 0 even where 'voicg' > 'vthr', especially 
%        if 'voicg' is only slightly > 'vthr' and exceeds 'vthr' for only short intervals.  
%        Conversely, 'voicg' may be 0 or < 'vthr' nearby -- but not always exactly at -- the
%        times when 'pc' (and/or 'pcont') = 0.  Generally, 'vthr' >= 0.20, the value that
%        is typical of white-noise signals [according to 'pitch_track'].
%  7.	'env' is smoothed over the shortest intervals characteristic of speech; for more
% 		typical intervals ~50-100 msec, simply smooth 'env' itself -- e.g., for 50 ms:
% 			smooth(env,round(0.050*RATE)) or smooth(env,-1-2*round(0.025*RATE))
%  8.	'deg_v' represents a more complete measure of the degree of voicing than does
% 		'deg_voiced(voicg,vthr)'.  Moreover, it represents the degree in the presence
% 		of thresholds that can be more appropriate than 'vthr', and rules that are more 
% 		complete than 'deg_voiced' implements for simple calls.  It is most closely related 
% 		to 'pcont' (not 'pc').
%  9.	This function will detect (apparent) voicing somewhat aggressively in high-noise 
% 		segments (though less so than 'pitch_track') and might be followed by more cautious 
% 		decisions if necessary.  'deghv' indicates degree of such aggressively detected
% 		harmonic voicing, though with stable pitch period.  'pitch_halfdbl' and 
% 		'deg_voiced' (with full input arguments) can be useful for more sophisticated
% 		decisions.  In this case, detecting substantial numbers of halvings and 
% 		doublings may be an indication of poorly determined period (due to high noise, 
% 		for example) OR to vocal anomalies; high power ('p0') at low frequencies can 
% 		sometime be used to exclude noise as the cause (or, conversely, to identify noise 
% 		as the cause and suppress the erroneous detection of voicing).
% 
%  See also: pitch_track, envelope, backupsample, sonorance, pitch_halfdbl, deg_voiced.
%
