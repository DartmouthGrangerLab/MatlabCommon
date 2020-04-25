%  Points of peak frication in 16-kHz signal, esp. by fractal dimension.
%  Syntax: [Flms] = fricative_lms(SIG16, <FIGNO>)
%  where:
% 	SIG16	= 16-kHz signal for analysis;
% 	<FIGNO>	= number of existing figure [default = none] for plots of related contours and
% 				pivot/landmark locations;
% 	Flms	= landmarks (LMs) of frication peaks: [time (sec); type; strength].
% 
%  Notes:
%  1.Frication is identified primarily by sustained, appropriate fractal dimension (5/3),
% 	as from 'audio_fractaldim16', and the difference between high- and low-frequency
% 	energy contours.  This version can miss true frication that is weak and/or brief (but
% 	rarely falsely detects non-fricatives).
%  2.The type (code) of any LM is always that for "FRICATION", i.e., the value of:
% 		lm_codes('FRICATION')
% 	This type does not distinguish among subtypes of frication, such as voiced or
% 	strident, even though strident frication is most routinely identified by this function.
% 	The functions 'lm2voicing', 'deg_voiced', and 'deg_strident' may be useful
% 	for distinctions among subtypes.
%  3.F-type LMs mark peaks or centers of frication.  They are not to be confused with the
% 	abrupt-type LMs that mark onsets (+f, +v) and offsets (-f, -v) of some frication or
% 	aspiration.
%  4.Some bursts are sufficiently long and prominent that they may be found among 'Flms'.
% 	If these need to be suppressed, they might be detected by adjacency to certain abrupt
% 	LMs (+-b, +-f).
% 
%  See also: audio_fractaldim16, lm2voicing, deg_voiced, deg_strident, lm_codes.
%
