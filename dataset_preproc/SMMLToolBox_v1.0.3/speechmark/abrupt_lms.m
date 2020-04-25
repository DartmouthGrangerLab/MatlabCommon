%  Consonantal landmarks of an acoustic speech-signal segment.
%  Syntax: [lms,bandrate,wdwlen,rorthr6] = ...
% 							abrupt_lms(SIGNAL,RATE,AGE,PREV_RORTHR6,<NOMED>,<VOICING,VRATE>)
%  where:
%    SIGNAL  = acoustic speech signal to be processed;
%    RATE    = samping rate of SIGNAL;
%    <AGE>	= "adult" [dflt.] or "child" (case-insens.) to cause the frequency-band 
% 			parameters to be set accordingly;
% 	<PREV_RORTHR> = threshhold, if any, [dB/msec; dflt. = NaN] used for six spectral
% 			bands' Rates Of Rise, to be blended (by 'blend_rorthresh') with limits 
% 			from current SIGNAL;
% 	<NOMED>	= "nomed" [case-insensitive] to suppress s/gram median filtering across 
% 			times, or "" [the dflt.] to perform this; the filtering is slow but 
% 			suppresses many brief, non-speech noises that can introduce (e.g.) 
% 			spurious landmarks;
% 	<VOICING> = vector of (fuzzy) degree of voicing, as from 'deg_voiced'; exactly 0 
% 			where the source has been determined to be unvoiced; if not provided, some 
% 			pairs of types will be merged (e.g., "burst" & "syl."); VOICING should be long
% 			enough that voicing can be determined for every detected landmark (see Note #6);
% 			-or-
% 			2xK array (for some "K") of:
% 				[vector fuzzy degree of voicing, as from 'deg_voiced'; 
% 				 vector fuzzy degree of periodicity, as from 'deg_voicedhnr']
% 			(see Note #7);
% 	<VRATE>	= samping rate [Hz] of VOICING (often 125); note that VRATE must be 
% 			supplied if VOICING is supplied, and vice versa;
% 	lms		= 3xN array of landmarks (+g/-g, +b/-b, etc), as from 'lm_codes', for 
% 			some N >= 0; each landmark is denoted by a time, type (code as returned
% 			by 'lm_codes'), and "degree"/"strength" (see Notes);
%    bandrate = sampling rate of spectrograms exhibiting the landmarks (generally a 
% 			sub-multiple of RATE, often 1 kHz);
%    wdwlen  = length of spectrogram window used to estimate energy; the first values 
% 			reflect energy centered in a window starting at the first sample, and of 
% 			'wdwlen' samples;
% 	rorthr6	= vector of min. thresholds [dB/msec] for "sufficiently" high rate of rise (or
% 			fall) (ror) for each of 6 coarse-pass bands separately; coarse and fine ror's 
% 			are scaled for common thresholds; this is a combination (as from 
% 			'blend_rorthresh') of SIGNAL information and PREV_RORTHR6.
% 
%  Notes: 
%  1.The "degree" or "strength" of a landmark (LM) is given by:
%  -	For an (oral) articulatory LM, the max. rate of rise[+] or fall[-] in log-energy
% 		[dB/msec] in the frequency band with the 3rd-most rapid rate at the given time (if
% 		>= 'rorthr6' in same frequency band); the ordinal 3 assumes that at least 3 bands
% 		must contribute in order to detect any LM at all in 'abrupt_events'.
%  -	For a voicing transition (assuming VOICING is given), the degree of voicing in 
% 		the adjacent voiced slice (of length 'wdwlen').
%  -	For a voiced articulatory LM, the fuzzy-And of articulatory and voicing "degrees" or
% 		"strengths".
%  2.The landmarks do not (quite) denote only the "primitive" LM information, i.e., purely 
% 	local and articulatory information (as from 'abrupt_events').  They incorporate 
% 	some non-local context and non-articulatory (e.g., voicing) information.
%  3.The acoustic features may be described using 'lm_features', the codes are given
% 	by 'lm_codes', and the 2-character symbols ("+b", etc.) may be obtained using 
% 	'lm_labels'.
%  4.It is generally helpful to high-pass filter SIGNAL first, to remove low-frequency 
% 	rumble and 60-Hz contamination (if any).  Typical limits are 75 Hz for AGE="adult",
% 	150 Hz for "child".
%  5.For simplicity, it may be helpful to quantize 'lms(1,:)' at VRATE; however, this is 
% 	not performed here.
%  6.If VOICING is not long enough to determine voicing for every detected landmark, it 
% 	is extended with VOICING(end).  However, this may not be ideal for the needs of the
% 	calling function (depending on the importance of context and other information).  
% 	Note that this occurs if LENGTH(VOICING)/VRATE < lmArray(1,end), a condition 
% 	which can never happen if LENGTH(VOICING)/VRATE >= LENGTH(SIGNAL)/RATE).
%  7.If SIZE(VOICING) = [K,2] for some "K" > 2, then the array will be transposed (and
% 	a warning given with 'warnmsg'); if K <= 2, the array will not be transposed.  
% 	Periodicity LMs will only be detected within voiced regions; thus, if periodicity 
% 	is detected outside of a voiced region (VOICING(2,j) = True but VOICING(1,j) = False,
% 	for some "j"), it will be ignored there.
%  8.Any features related to F0 are not handled here, except to the extent that they are
% 	described by the degree or strength of the feature (e.g., of periodicity, or of
% 	voicing itself).  In particular, F0-jump LMs depend on F0 itself and are therefore not
% 	handled here.
% 
%  See also: deg_voicing, blend_rorthresh, lm_labels, lm_features, lm_codes, abrupt_events,
% 	deg_voicedhnr.
%
