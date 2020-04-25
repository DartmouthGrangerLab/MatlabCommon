%  Abrupt landmarks (time, sign, strength) for jump discontinuities in pitch period.
%  Syntax:	[jlms,jndxs] = jump_lms(TMS,PER,<PDEG>)
%  where:
% 	TMS	= times [sec] at which PER is evaluated; normally, uniformly at 125 Hz, <=> .008 sec;
% 	PER	= pitch-period estimate [msec] (1/fundamental frequency F0) at each value of TMS;
% 	<PDEG> = degree (in 0-1) of strength of periodic voicing [default = 1], as from
% 		'deg_voicedhnr' or 'deg_voicedhnr_std'; either a vector of the same length as PER
% 		or else a scalar in 0-1; if specified as 0 (scalar), a warning will be given with
% 		'warnmsg', and no jumps will be detected;
% 	jlms = [time; type; strength (degree)] of jump discontinuities in pitch (F0): type +j
% 		for increasing F0, -j for decreasing; if no jumps are detected, this will have size
% 		3x0;
% 	jndxs = indexes (into TMS) of jumps listed in 'jlms'; the jump occurs between
% 		'jndxs-1' and 'jndxs', typically at a time = (TMS(jndxs-1)+TMS(jndxs))/2.
% 
%  Notes:
%  1.TMS must consist mostly of uniformly spaced times: .008 sec is typical.  If there are 
% 	occasional changes of spacing, the arrays will be split at the changes and processed
% 	individually.  However, this could sometimes cause the insertion or loss of a jump
% 	landmark near the split.  The intervals of uniform spacing must consist of at least
% 	several samples (~5-10) AND span at least ~30 msec or no jumps will be found.  
% 	Therefore, rapid changes of spacing in TMS should be avoided.  Note that these changes
% 	of spacing are only caused by processing, not by voicing, so they can in principle be
% 	avoided by the caller.
%  2.Stable pitch and strong harmonics may still allow occasional period-doubling and 
% 	period-halving.  This can be characteristic of perceptually well vocalized speech, 
% 	though perhaps objectively poorly controlled (as with infants).  They can be part of 
% 	PER and will generate jump landmarks.  It is appropriate to set PDEG from
% 	'deg_voicedhnr_std' in this case.  However, if such jumps are NOT of interest, they
% 	can be removed with 'pitch_halfdbl' before calling this function.  In that case,
% 	'deg_voicedhnr' and 'deg_voicedhnr_std' will normally produce the equal estimates of
% 	PDEG.
%  3.It is appropriate to set PER to 0 or NaN at times when it is too large or small, or 
% 	when voicing is too weak (e.g., harmonics/noise ratio HNR < a few dB).  For example,
% 	if it should never be smaller (higher pitch) than some value PMIN, then use a
% 	statement such as
% 		jlms = jump_lms(TMS, PER.*(PER>=PMIN));
% 	Likewise, if intervals of very low power or of low HNR should be excluded, then use
% 	a similar expression to set the corresponding PER values to zero or NaN.
% 	If PDEG is supplied, this can be achieved by instead setting PDEG = 0 at such points.
%  4.See 'deg_voicedhnr[_std]' for other notes on PER and its interactions with HNR.
%  5.A jump is characterized by the larynx shifting abruptly into a new regime (attractor),
% 	with at least a somewhat different F0 sustained for at least ~ 20 msec and at least
% 	twice the shortest period.  The minimum change detected here is ~0.1 octave occurring
% 	over ~ 12 msec or less. (See 'deg_voicedhnr[_std]' for transitions that indicate an
% 	actual loss of periodicity.) A jump is only detected if F0 changes by at least ~0.1
% 	octave AND by at least the local variability.  Local variability is defined by
% 	comparing DIFF(PER) to approximately its local range (max-min).  F0 changes in the
% 	single sample at the start or end of an interval with PER > 0 are generally NOT
% 	detected as jumps, regardless of magnitude.
%  5.The degree of a jump landmark is between 0 and 1, related to the magnitude of the
% 	jump compared to the local variability (but reduced to the value of PDEG at the same 
% 	moment in time, if lower). However, changes that are smaller than the threshold ~ 0.1 
% 	octave are not marked as jumps at all.
% 	The time of a landmark is either an element of TMS or the mean of 2 adjacent elements
% 	of TMS.  (In the latter case, the degree will be taken from the min of the two PDEG
% 	elements, if PDEG is supplied.)
%  6.If the interval between adjacent samples of TMS is outside the range ~ 6-15 msec,
% 	i.e., much shorter or much longer than ~8-12 msec, jumps may not be properly detected.
% 	The standard interval in most pitch tracking (e.g., in 'landmarks', 'pitch_track', and
% 	'nonbreathy') is 8 msec, well within this range.
%  7.To convert the numeric type to a label ("+j", "-j"), use 'lm_labels'.
% 
%  See also: pitch_halfdbl, deg_voicedhnr, deg_voicedhnr_std, landmarks, pitch_track,
% 	nonbreathy, warnmsg, lm_labels.
%
