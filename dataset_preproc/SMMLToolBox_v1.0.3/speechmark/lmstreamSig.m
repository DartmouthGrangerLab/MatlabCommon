%  lmstreamSig combines the functionality of 'abrupt_lms' (processes the entire signal at once) 
%  and 'lmstreamer' (processes short pieces at a time).
%  Syntax: [lms,ptimes,pcont,env,envthr,degv,dvthr] = lmstreamSig(SIGNAL,RATE, WINDOW_LEN, OVERLAP, AGE_GENDER)
%  where:
% 	SIGNAL	= the signal (array) to be processed; 
% 	RATE	= its sampling rate [Hz];
% 	WINDOW_LEN = the length [seconds] of each segment to be processed;
% 	OVERLAP	= the overlap [seconds: default = 0.05] of segments;
% 	AGE_GENDER = (case-insensitive) label [dflt. = "i" (infant)] for age and/or gender of 
% 			subject, as for 'maxf0_std';
%    lms		= 3xN landmark array;
% 	ptimes	= times [seconds] at which 'pcont' is evaluated;
%    pcont   = pitch-period contour (in MSEC, not Hz!), at times in 'ptimes';
% 	env		= envelope of (DIFF of) SIGNAL; SIZE(env) = SIZE(DIFF(SIGNAL));
% 	envthr	= APPROXIMATE (constant) threshold on 'env' below which SIGNAL is ignored;
% 	degv	= degree (0-1) of voicing, evaluated at times in 'ptimes';
% 	dvthr	= threshold on 'degv' used to determine voicing.
% 
%  It finds consonantal landmarks in the signal (~ 'abrupt_lms').
% 	0.2 to 0.25 is typical WINDOW_LEN for real-time simulation;
%  The window length may be specified as the signal length.  This is the
%  default, if the 3rd arg. is [] or missing.  This is similar to using 'abrupt_lms'.
%  It may use a shorter window length (segment length) if the signal is too large to process
%  at once (e.g. 10 minutes @ 16 kHz).
%    -> NOTE: This version, however, requires the WHOLE signal at the start,
%            even though processing is performed in segments.  This saves
%            most of the memory that would otherwise be used, but not all.
%  It may use a small window length (segment length), e.g. 200 ms, to simulate real-time 
%  analysis of the signal.
%  For multiple-segment processing (window length < signal length), the
%  amount of overlap in time may be specified in seconds.  The default, if [] or
%  missing, is .050 sec.  (This is irrelevant if the window
%  length = [], i.e., if there will only be a single segment.)
% 
%  This function will give a warning (through 'warnmsg') if OVERLAP is non-0 and WINDOW_LEN
% 	is explicitly given as LENGTH(SIGNAL).  Whis warning will be suppressed if WINDOW_LEN
% 	if defaulted (even though its value in that case is equal to LENGTH(SIGNAL)).
% 
%  Note that this function has similar but NOT identical outputs to 'lmadult'.
% 
%  See also: warnmsg, abrupt_lms, lmstreamer, lmstreamFile, mat_streamlms, maxf0_std, lmadult.
%
