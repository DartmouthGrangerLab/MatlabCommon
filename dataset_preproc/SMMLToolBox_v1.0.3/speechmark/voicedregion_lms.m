function [onoff_ndxs,off_ndxs] = voicedregion_lms(LMARRAY)
% Sorted indices of LMs (of a speech-acoustic signal) of syllables covering voiced regions.
%	onoff_lms_2xK = voicedregion_lms(LMARRAY|LMSTRUCT)
%	-OR-
%	[on_lms_1xK,off_lms_1xK] = voicedregion_lms(LMARRAY|LMSTRUCT)
% where:
%   LMARRAY|LMSTRUCT = 2xN or 3xN numeric array, or 1xN structure array, of glottis, burst, 
%		sonorant-consonant, etc., landmarks (+g/-g, +b/-b, +s/-s), for some N >= 0, as from 
%		'landmarks'; each LM is denoted by (at least) a time & type (index);
%	onoff_lms_2xK = [start;stop] indices (into the LM array) of the "K" voiced regions
%	-OR-
%	on_lms_1xK	= starting indices (into the LM array) of the "K" voiced regions; see Notes;
%	off_lms_1xK	= ending indices of the "K" voiced regions.
%
% Notes:
% 1.The "k"-th pair of output indices are the starting & ending LMs of the syllables covering
%	the "k"-th voiced region.  For example, in the LM sequence
%		+b +g -g -b | +g | +s -g | +b
%	where "|" marks syllable boundaries, there are 3 syllables (excluding the final, isolated 
%	+b) and 2 voiced regions, marked by the two +g -> -g intervals.  The function would return:
%		on_lms	= [1, 5]
%		off_lms	= [4, 7].
%	Thus, the LMs [on_lms(1):off_lms(1)] = 1:4 are the LMs of the first syl., which covers voiced 
%	region #1.  And [on_lms(2):off_lms(2)]= 5:7 are those of the TWO syl's. that cover region 
%	#2.  Notice that:
%	- Each starting index is the starting index of some syllable, as determined by 'syl_lms'.
%	- Each ending index is the ending index of some syllable, likewise.
%	- The indices are in strictly increasing order.  Thus, the syl's. associated with each
%	region are in strictly increasing (time) order.
% 2.If the first landmark ENDS a syllable (e.g., "-g" type), the corresponding onset index will
%	be set to -Inf.  If the last one is voiced but does NOT end a syllable (e.g., "+s"), the 
%	offset index will be set to +Inf.
% 3.If LMARRAY (or LMSTRUCT) starts with a voiced LM (not only "+g"), the first syl. will be 
%	taken to start at that LM.
% 4.Although a proper LM array (numeric or structure) should never contain consecutive "+g"s 
%	nor "-g"s, this function will accept such a sequence and ignore all but the first, with a 
%	warning (though 'warnmsg').
% 5.The function 'lm_sylfilter' will filter all LMs in quiet syllables, based on this function.
%	This can be useful in suppressing aggressively detected LMs in the presence of background
%	sounds or noise.
% 6.The restriction to syllables containing both +g and -g avoids the ambiguous problem of:
%		+g -s | +s -g (where "|" denotes a syl. boundary);
%	if either syl. were suppressed, but the other were not, then the resulting LM sequence
%	would have an unpaired "g", an invalid condition.  The effect of this function is to
%	group all syllables within a single voiced region, so that all can be kept or suppressed
%	(as by 'lm_sylfilter') together.
%
% See also: syl_lms, utt_lms, lm_sylfilter, warnmsg.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2010-2011, Speech Technology & Applied Research Corp. (unpublished)
%
%	JM	11/10/8	Fix defect for empty LMARRAY when NARGOUT = 0.

% Codes for the simple landmark types:
% Landmark INDICES:
persistent MINUS_G PLUS_G
if isempty(MINUS_G),
    [MINUS_G PLUS_G] = lm_codes('MINUS_G','PLUS_G');
end

if nargin==1 && isequal(LMARRAY,'?'),
    fprintf('%s\n', 'onoff_ndxs_2xK = voicedregion_lms(LMARRAY_2xN|LMSTRUCT_N)')
    fprintf('%s\n', '[on_ndxs_1xK,off_ndxs_1xK] = voicedregion_lms(LMARRAY_2xN|LMSTRUCT_N)')
    return
end

if isempty(LMARRAY),	% 11/10/8: Fix defect for NARGOUT = 0: Was: if nargout == 1, ...
    if nargout <= 1, onoff_ndxs = zeros(2,0); else onoff_ndxs = []; off_ndxs = []; end
    return
end

if isstruct(LMARRAY), 
	lm_structarr(LMARRAY);	% >> ISNUMERIC(ans) = true; SIZE(LMARRAY,2) = SIZE(ans,2). <<
		if nargout == 2, [onoff_ndxs,off_ndxs] = voicedregion_lms(ans);
		else, onoff_ndxs = voicedregion_lms(ans);	% NARGOUT = 1 OR 0.
		end
	return
end

%Find syllable boundaries
[on_ind,off_ind] = syl_lms(LMARRAY);

%Find [+g -g] pairs
plusg_ind = find(LMARRAY(2,:) == PLUS_G);
minusg_ind = find(LMARRAY(2,:) == MINUS_G);
if isempty(plusg_ind), plusg_ind = on_ind; end
if isempty(minusg_ind), minusg_ind = off_ind; end

onoff_ndxs = zeros(1,length(plusg_ind));
off_ndxs = zeros(1,length(minusg_ind));

%Concatenate results from syl_lms to [+g -g] pairs
if ~isempty(plusg_ind) && ~isempty(minusg_ind)
    if plusg_ind(1) > minusg_ind(1), plusg_ind = [on_ind(1) plusg_ind]; end
    if minusg_ind(end) < plusg_ind(end), minusg_ind = [minusg_ind off_ind(end)]; end
    
    for kk = 1:length(plusg_ind)
        (plusg_ind(kk) >= on_ind) & (plusg_ind(kk) < off_ind);
	        onoff_ndxs(kk) = on_ind(ans);
        (minusg_ind(kk) <= off_ind) & (minusg_ind(kk) > on_ind);
	        off_ndxs(kk) = off_ind(ans);
    end
end

if nargout <= 1, onoff_ndxs = [onoff_ndxs;off_ndxs]; end
