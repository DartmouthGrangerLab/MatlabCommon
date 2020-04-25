function signogaps = lm_signal_nogaps(SIGNAL,RATE,LMARRAY,UTT_GAP)
% Speech-acoustic signal with inter-utterance gaps removed according to a landmark array.
% Syntax: 
%	signogaps = lm_signal_nogaps(SIGNAL,RATE,<LMARRAY>,<UTT_GAP>)
% where:
%	SIGNAL	= the speech-acoustic signal from which to remove all inter-utterance gaps;
%	RATE	= the sampling rate [Hz] of SIGNAL;
%   LMARRAY	= 2xN or 3xN numeric array, or equivalent structure array, of landmarks, for 
%				some N >= 0; each landmark is denoted by a time & type code; 
%			if empty, it will be computed with default max. F0 (according to 'maxf0_std') 
%			from 'lmadult', i.e., assuming an adult speaker;
%	<UTT_GAP> = inter-utterance gap [sec]; see Notes;
%	signogaps = copy of SIGNAL with all inter-utt. segments removed or shortened.
%
% Notes: 
% 1.This function can be particularly helpful in computing certain local temporal properties,
%	such as modulation, restricted to speech-like intervals.
% 2.If non-empty, LMARRAY must be a valid sequence of LMs (avoiding, e.g., consecutive +g's).
%	If LMARRAY is empty or absent, 'lmadult' will compute the array; however, if this latter 
%	array is also empty, then 'signogaps' will be [].
% 3.Utterance status is determined by 'lm2inutt' based on LMARRAY and UTT_GAP.
% 4.The default value of UTT_GAP is set by 'lm2inutt'; however, the "standard" value
%	given by 'utt_gap_std()' may be different, depending on the application.  Specify
%	UTT_GAP = NaN to use the 'utt_gap_std' value.
% 5.The function 'lm_sylfilter' filters out all syllables, and the corresponding LMs, in very 
%	quiet intervals.  This can remove unreliable LMs, potentially shortening the utterances
%	detected here, i.e., shortening 'signogaps'.
% 6.No special processing occurs at utt. boundaries.  Thus, 'signogaps' may have discontinuities
%	and other artifacts at these points.
%
% See also: lmadult, maxf0_std, utt_lms, utt_gap_std, lm2inutt, lm_sylfilter.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2011, Speech Technology & Applied Research Corp. (unpublished)
%
%   RP 14/9/22 Apply function name change from std_* to *_std. Also, reflact changes in doc.

if nargin==1 && isequal(SIGNAL,'?'),
    fprintf('%s\n', 'signogaps = lm_signal_nogaps(SIGNAL,RATE_Hz,<LMARRAY>,<UTT_GAP_sec|NaN>)')
	fprintf('\tbased on:\n')
	lm2inutt ?
    return
end

if nargin < 3, LMARRAY = []; end
if nargin < 4, UTT_GAP = []; end
if isstruct(LMARRAY),	% Recurse just once for this:
	signogaps = lm_signal_nogaps(SIGNAL,RATE,lm_structarr(LMARRAY),UTT_GAP); 
	return
elseif isempty(LMARRAY)	% Recurse just once for this:
	% We separate the determination of the LM array, in case SIGNAL truly has no LMS (which 
	%	would otherwise cause infinite recursion):
	lmadult( SIGNAL,RATE,maxf0_std()); % 14/9/22 Apply name change.
		if isempty(ans), signogaps = [];
		else, signogaps = lm_signal_nogaps(SIGNAL,RATE,ans,UTT_GAP);	% Single recursion.
		end
	return	
end
	% >> LMARRAY is a non-empty,  numeric (non-structure) array. <<

(1:length(SIGNAL)) / RATE;	% All the times for which we need to know the utt. status.
	lm2inutt(LMARRAY,ans,UTT_GAP);	% >> (Error or:) SIZE(ans) = SIZE(SIGNAL); CLASS(ans) = Logical. <<
	% ++ Could use PCHIP here, to smooth transitions (->0); with Log. indexing where still = 0.
	signogaps =	SIGNAL(ans);	% Exclude inter-utt. remainder.
