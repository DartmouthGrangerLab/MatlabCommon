%  LMSTREAMER is intended for real-time processing of a signal so that short 
%  segments of a signal are passed to it with information (OFFSET, PREV_RORTHR, 
%  VOICED, OVERLAP, AGE_GENDER, MAX_F0, ENVFLOOR) about the last processed segment.  
%  
%  Syntax: function [lmslocal,rorthr, voiced, pcont, pcrate, tms, env, envthr, degv, dvthr]  = ...
% 			lmstreamer(Y, FS, PREV_LMS, OFFSET, PREV_RORTHR, VOICED, OVERLAP, ...
% 						AGE_GENDER, MAX_F0, ENVFLOOR)
%    Where:
%    Y           = the input signal
%    FS          = the recording frequency
%    PREV_LMS    = previously returned landmarks, ***maybe just the last one.
%    OFFSET      = the starting time of the signal Y
%    PREV_RORTHR = the last threshhold used to compute the band Rate Of Rise
%    VOICED      = true if voicing was present at the end of the last "reliable" part of
% 				the last processed region. See Note 3.
%    OVERLAP     = seconds of overlap of successive signal segments
% 	<AGE_GENDER> = (case-insensitive) label for age and/or gender of subject, as for 
% 					'maxf0_std'; the default is "n" (adult neutral);
%    <MAX_F0> 	= [Hz] max. for any candidate (i.e., "sensible") fund. freq. F0 to be
% 				  considered for pitch-tracking [default taken from 'maxf0_std(AGE_GENDER)'];
% 		-OR-
% 		<MAXMIN_F0> = [max., min.] values allowed for any candidate F0 [Hz]; see 
% 				'maxf0_std' for the default min. value;
% 	<ENVFLOOR>	= value of 'env' [dflt. = 0] below which Y will be taken to be silent, if 
% 				  higher than 'envthr'.  (See below for 'env', 'envthr'.) See Note 4.
%    lmslocal    = (array) of glottis, burst, and sonorant landmarks (+g/-g, +b/-b, +s/-s, etc.)
%                  (and the times they occurred) for current segment Y
%    rorthr      = the new threshhold used to compute the band Rate Of Rise
%    voiced      = true if voicing was present at the end of the "reliable" part of the region 
%                  processed, i.e., just before OFFSET+LENGTH(Y)/Fs-OFFSET/2;
%    pcont       = pitch-period contour (in MSEC, not Hz!), at sampling rate 'pcrate' (typically 125 Hz).
% 	pcrate      = time interval [sec] between successful values of 'pcont'; typically, .008 sec;
% 	tms         = times at which 'pcont' is evaluated;
% 	env         = envelope of (DIFF of) Y; SIZE(env) = SIZE(DIFF(Y));
% 	envthr      = threshold on 'env' below which Y is ignored;
% 	degv        = degree (0-1) of voicing, evaluated at 'tms' times;
% 	dvthr       = threshold on 'degv' used to determine voicing; note that this does NOT vary with
%                  the signal or other inputs.
%  
%  Notes:
%  1.Note that this function has similar but NOT identical outputs to 'landmarks' and 
% 	'lmstreamSig'.
%  2.The landmark-processed region is centered in the segment and has length 
% 		(1 - OVERLAP)*length(segment).
%  3.VOICING is typically measured just BEFORE OFFSET+OVERLAP/2 (which might not be reliably 
%    estimated from the current segment of the signal, due to too little context).
%  4.Generally, ENVFLOOR should be a value determined by either the noise floor (if known)
% 	or by a conservative measure of amplitude, such as
% 		(highest previously encountered value of 'env') / 1000,
% 		(a value which produces behavior similar to 'lmadult') or perhaps
% 		0.1*MAX(previous value of 'env')/1000 + 0.9*(previous value of ENVFLOOR).
%  	The purpose is to allow suppression of a very quiet segment, one for which 'envthr' 
%  	might be unrealistically low.  The value NaN is equivalent to 0.
%  
%  Example:
%  
%  
% 
%  
% 
%  See also: maxf0_std, lmadult, lmstreamSig.
%
