%  "Primitive" consonantal landmarks of an acoustic speech-signal segment.
%  Syntax: [lms,bandrate,wdwlen,rorthr6] = ...
% 							abrupt_events(SIGNAL,RATE,AGE,PREV_RORTHR6,NOMED,FIGNO)
%  where:
%    SIGNAL  = acoustic speech signal to be processed;
%    RATE    = samping rate of SIGNAL;
%    <AGE>	= "adult" [dflt.] or "child" (case-insens.) to cause the frequency-band 
% 			parameters to be set accordingly;
% 	<PREV_RORTHR6> = threshhold, if any, [dB/msec; dflt. = NaN] used for six spectral
% 			bands' Rates Of Rise, to be blended (by 'blend_rorthresh') with limits 
% 			from current SIGNAL;
% 	<NOMED>	= "nomed" [case-insensitive] to suppress s/gram median filtering across 
% 			times, or "med" [the dflt.] to perform this; the filtering is slow but 
% 			suppresses many brief, non-speech noises that can introduce (e.g.) 
% 			spurious landmarks;
% 	<FIGNO>	= figure number into which to plot rates of rise and LM positions, for each band:
% 				[] (the default) if none;
% 				0 for new figure;
% 				else number;
% 	lms		= 3xN array of "primitive" consonantal landmarks (+s/-s, +b/-b, etc), as from 
%            'lm_codes', for some N >= 0; each landmark is denoted by:
% 				a time [secs];
% 				type: a code as returned by 'lm_codes'; and 
% 				"strength": max. rate of rise[+] or fall[-] in log-energy across 
% 				all broad freq. bands at the given time, COMPARED to the corresp.
% 				threshold (i.e., 'rorthr(<approp. band>)'); units = [dB/msec].
%    bandrate = sampling rate of 'bands' & 'bandsf' (generally a sub-multiple of RATE);
%    wdwlen  = length of spectrogram window used to estimate energy; the first values 
% 			reflect energy centered in a window starting at the first sample, and of 
% 			'wdwlen' samples.
% 	rorthr6	= vector of min. thresholds [dB/msec] for "sufficiently" high rate of rise 
% 			(or fall) for each of 6 coarse-pass bands separately; coarse and fine ror's 
% 			are scaled for common thresholds; this is a combination (as from 
% 			'blend_rorthresh') of SIGNAL information and PREV_RORTHR6.
%    bands, -f = coarse, fine smoothings of log(energy) [dB] in each frequency band.
% 
%  Notes: 
%  1."Primitive" refers to the purely local and artic. nature of the information, 
% 	without incorporation of non-local context or non-artic. (e.g., voicing) info.
% 	The types are as follows:
% 		-+b ~ burst (unvoiced) or syllabic, i.e., son. cons. release (voiced)
% 		-+f	~ fricative (voiced or unvoiced);
% 	the codes are as returned by 'lm_codes', the corresponding acoustic features 
% 	may be described using 'lm_features', and the 2-char. symbols ("+b", etc.) may 
% 	be obtained using 'lm_labels'.
%  2.It is generally helpful to high-pass filter SIGNAL first, to remove low-freq. 
% 	rumble and 60-Hz contamination (if any).  Typical limits are 75 Hz for AGE="adult",
% 	150 Hz for "child".  See 'hpfilt_std'.
%  3.If plotted, LM positions are marked by "+" on each band's axis; for the band that
% 	defines the LM's strength, the "+" is circled.
% 
%  See also: blend_rorthresh, lm_labels, lm_features, lm_codes, hpfilt_std.
%
