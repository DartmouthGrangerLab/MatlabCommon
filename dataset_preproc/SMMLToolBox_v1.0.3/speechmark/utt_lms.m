%  Sorted indices (into LM array of a speech-acoustic signal) of utterance onsets and ends.
% 	onoff_lmndxs = utt_lms(LMARRAY,<SIG_END_TIME>,<UTT_GAP>)
% 	-OR-
% 	[on_lmndxs,off_lmndxs] = utt_lms(LMARRAY,<SIG_END_TIME>,<UTT_GAP>)
%    LMARRAY	= 2xN or 3xN array of glottis, burst, sonorant, etc., landmarks (+g/-g, +b/-b, 
% 			+s/-s), for some N >= 0, as from 'lmadult'; each landmark is denoted by 
% 			a time & type (index);
% 	<SIG_END_TIME> = time [Secs: dflt. +Inf] of end of processed signal corresp. to LMARRAY;
% 			utterances that do not end before SIG_END_TIME will be taken to end at SIG_END_TIME; 
% 	<UTT_GAP>	= minimal interval [Secs] [dflt. ~ 0.35] between utt's.; specify NaN to
% 			force the use of 'utt_gap_std' (see Notes);
% 	on_lmndxs	= indexes (into LMARRAY) of the landmarks that begin each utterance;
% 	off_lmndxs	= indexes that terminate each utterance, similarly;
% 	onoff_lmndxs = [on_lmndxs; off_lmndxs].
% 
%  Notes:  
%  1.If the first landmark unambiguously signals an END to a syllable (e.g., "-g" type, but 
% 	NOT "-b"), the corresponding onset index will be set to 0.  If the last one unambiguously 
% 	FAILS to end an utterance (e.g., "+s"), the offset index will be set to +Inf.  See
% 	the Examples.
%  2.If LMARRAY starts with any voiced LM (not only "+g"), the utterance will be taken to 
% 	start at that LM.
%  3.Some landmarks in LMARRAY may not be part of any utterance.  Also, some may be part
% 	of an utterance but not part of any syllable (per 'syl_lms').
%  4.The default value of UTT_GAP is fixed (approx. 350 ms); however, the "standard" value
% 	given by 'utt_gap_std()' may be different, depending on the application.  Specify
% 	UTT_GAP = NaN to use the 'utt_gap_std' value.
%  5.The function 'lm_sylfilter' will remove LMs in quiet syllables, if envelope information
% 	is available.  This can produce a more reliable indication of utterance boundaries, if 
% 	noise or background sounds have created many extra LMs.
% 
%  Examples:
%  1.For lms = [.2	.6	.9	1.2	1.4	1.5	1.7	2.12 2.17;
% 				1	2	1	2	1	2	1	2	1], with LM labels of:
% 				-g	+g	-g	+g	-g	+g	-g	+g	-g],
% 		>> [ons, offs] = utt_lms(lms)
% 	returns 'ons' = [2 8], 'offs' = [7 9].
%  2.For lms = [.2	.5	.9	1.2	1.4	1.5	1.7	2.12 2.17;
% 				1	2	1	2	1	2	1	2	1],
% 	i.e., differing from Ex. #1 ONLY in 'lms(:,2)' occurring < 'utt_gap_std()' after 'lms(:,1)',
% 		>> [ons, offs] = utt_lms(lms)
% 	returns 'ons' = [0 2 8], 'offs' = [1 7 9].  Thus, even the first LM occurs within an utt.
% 	that started before 'lms(1,1)' (so it is assigned an "index" of 0).
%  3.For the same 'lms',
% 		>> [ons, offs] = utt_lms( lms(:,1:end-1))
% 	returns 'ons' = [0 2 8], 'offs' = [1 7 Inf].  Thus, the final LM does not signal an utt.
% 	end, so it is assigned the index value +Inf.
% 
%  See also: lmadult, syl_lms, lm_sylfilter, utt_gap_std.
%
