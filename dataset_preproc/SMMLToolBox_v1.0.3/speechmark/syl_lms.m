% Sorted indices (into landmark array of a speech-acoustic signal) of syllable-cluster onsets and ends.
% 	onoff_lms_2xK = syl_lms(LMARRAY)
% 	-OR-
% 	[on_lms_1xK,off_lms_1xK] = syl_lms(LMARRAY)
%    LMARRAY	= 2xN array of glottis, burst, sonorant, etc., landmarks (+g/-g, +b/-b, +s/-s),
%    		for some N >= 0, as from 'lmadult'; each landmark is denoted by a 
% 			time & type (index).
% 
%  Notes:  
% 1.If the first landmark (LM) ENDS a syllable (e.g., "-g" type), the corresponding onset index 
%	will be set to -Inf.  If the last one does NOT end a syllable (e.g., "+s"), the offset index 
%	will be set to +Inf.
% 2.If LMARRAY starts with a voiced LM (not only "+g"), the first syllable cluster will be 
%	taken to start at that LM.
% 3.Although a proper LMARRAY should never contain consecutive "+g"s nor "-g"s, this 
% 	function will accept such a sequence and ignore all but the first, with a warning
% 	(though 'warnmsg').
% 4.The function 'lm_sylfilter' will filter all LMs in quiet syllables.  
% 
%  See also: lmadult, utt_starts, warnmsg.
