%  Time-indexed array for within-an-utterance according to a landmark array.
%  Syntax: 
% 	inutt = lm2inutt(LMARRAY,TMS,<UTT_GAP>),
%  where:
%    LMARRAY	= 2xN or 3xN numeric array, or equivalent structure array, of landmarks, for 
% 			some N >= 0; each landmark is denoted by a time & type code;
% 	TMS		= times at which to evaluate 'inutt';
% 	<UTT_GAP> = inter-utterance gap [sec]; see Notes;
% 	inutt	= utterance status (according to 'utt_lms') at each time in TMS; entirely False
% 			if LMARRAY is empty.
% 
%  Notes: 
%  1.LMARRAY must be a valid sequence of LMs (avoiding, e.g., consecutive +g's).
%  2.Utterance boundaries are determined according 'utt_lms'.  A time is considered to be
% 	within an utterance if the onset is <= the time, and the time is strictly < the offset.
%  3.The default value of UTT_GAP is set by 'utt_lms'; however, the "standard" value
% 	given by 'utt_gap_std()' may be different, depending on the application.  Specify
% 	UTT_GAP = NaN to use the 'utt_gap_std' value.
%  4.The function 'lm_sylfilter' filters out all syllables, and the corresponding LMs, in very 
% 	quiet intervals.  This can remove unreliable LMs, potentially shortening the utterances
% 	detected here, i.e., lengthening detected inter-utt. gaps.
% 
%  See also: landmarks, utt_lms, lm_sylfilter.
%
