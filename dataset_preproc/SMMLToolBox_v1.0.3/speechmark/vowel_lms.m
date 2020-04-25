%  Find vowel landmarks in "good" vocalic segments of signal.
%  Syntax:	[vlms,vf,tvals] = vowels_lms(SIGNAL, Fs, <MAX_F0>,<ENV>)
%  where:
% 	vlms	= [time; degree] of "most vocalic" instant(s) in SIGNAL; see Notes;
% 	vf		= voiced fraction of signal's power at certain times (in the range [0-1]);
% 	tvals	= times [seconds; COLUMN] at which 'vf' is evaluated;
% 	SIGNAL	= speech signal to be analyzed;
% 	Fs		= sampling freq. for SIGNAL; it is generally best if Fs < 12 kHz
% 			(especially, 8 kHz), since vowel energy in adults is typically weak, 
% 			but frication energy may be high, above 6 kHz, or even 4 kHz;
%    <MAX_F0> = [Hz] max. for any candidate (i.e., "sensible") fund. freq. F0 to be
% 			considered [dflt. = 'pitch_track''s default];
% 		-OR-
% 		<MAXMIN_F0> = [max., min.] values allowed for any candidate F0 [Hz]; see 
% 				'maxf0_std' for the default min. value;
% 	<ENV>	= weighting function [dflt = ONES(SIZE(SIGNAL))] for choosing local 
% 			maxima of "voicing strength" of segment; sampled at Fs; will be 
% 			padded with ENV(end) if shorter than length(SIGNAL); see Notes.
% 
%  Notes:
%  1.This function identifies voicing fairly aggressively (likely more aggressively
% 	than 'lmadult'); thus, it is possible that vowel landmarks are identified in
% 	segments that are identified elsewhere as "unvoiced".  The "degree" is negated 
% 	if the duration of voicing is too short (<~ 15 ms) for normal adult speech; the 
% 	specific value of the minimum duration is implementation-dependent but is likely
% 	to be shorter than in 'lmadult' and similar functions.  Consequently, 'vlms'
% 	should be filtered according to further criteria if a more conservative list is
% 	needed.
%  2.The "degree" returned for the landmark is based on the local strength of voicing 
% 	only; it is not multiplied by ENV (even though the LOCATION at which the landmark 
% 	is placed represents a local max. of the "degree" multiplied by ENV).  The "degree" 
% 	approx. represents the voiced fraction of (local) energy.
%  3.Typically, ENV is the amplitude envelope of SIGNAL, or of DIFF(SIGNAL), or of
% 	a low-pass version of DIFF(SIGNAL) for freq's. <~ 2 kHz, smoothed over 
% 	intervals ~ 50 msec, as from 'lmadult'.  A primary purpose of
% 	ENV is to specify intervals that are to be ignored entirely (ENV=0), such
% 	as intervals already known by other means to be unvoiced or to contain only
% 	non-speech.  See 'envelope', 'envelope0', and 'lowpass2'.
%  4.It is often helpful to suppress near-silent intervals of SIGNAL by
% 	using 'nonquiet' or 'nonquiet_ctr' before calling this function.
%  5. The times at which voicing starts & ends ('vf' > 0) are often uncertain by ~20 msec.
% 
%  See also: lmadult, pitch_track, nonquiet, nonquiet_ctr, envelope, envelope0, lowpass2.
%
