%  Remove LMs in and spanning intervals "axed" with hand-marks.
%  Syntax:	posnskeep = lm_hmfilt(LMFULL,<HMARKS>)
%  where:
% 	LMFULL	= initial time-ordered landmark numeric or structure array including times and 
% 			types; see Notes for requirements;
% 	<HMARKS> = time-ordered numeric or structure array [dflt. = none] of hand-marks 
% 			indicating time intervals to be ignored ("axed"); see Notes for requirements;
% 	posnskeep = positions (in LMFULL) of the subset of LMFULL for non-"axed" intervals;
% 			Logical (True = non-axed), of size = [1, SIZE(LMFULL,2)].
% 
%  Notes:
%  1."Axing", i.e., suppression of landmarks in certain intervals, is typically useful for
% 	analysis of signals that contain "corrupting" sounds; i.e., environmental sounds that
% 	might be confusable with speech, speech from talkers other than the one(s) under study,
% 	or non-speech vocalizations (unless these are of interest).
%  2.If numeric, LMFULL(1:2,:) must consist of [times;type code], where times are in seconds
% 	and codes are as from 'lm_codes'.  
% 	If structural, LMFULL("k") must contain "time" and "type" fields, for every "k", as 
% 	from 'lm_structarr'.
%  3.If numeric, HMARKS(1:2,:) must consist of [times;axing codes], where times are in 
% 	seconds and axing codes are 1 for start of axing and 0 for end of axing.  
% 	If structural, HMARKS("k") must contain "time" and "ax" fields, for every "k"; the 
% 	time field must be measured in seconds, the ax field must consist of the string "ax" 
% 	(for start of interval to be ignored) or "zx" (for end of such an interval).
%  4.Certain LMs immediately preceding or following an axed interval may be removed as well.
% 	For example, a +g immediately before an axed interval will be deleted, because its 
% 	corresponding -g cannot be determined.
%  5.HMARKS should consist of a strict alternation of codes, although this is not checked.
% 	The first code is typically onset ("ax"), although this is not required.  Hand-marks
% 	are often created with PRAAT as textgrid-files and read into MATLAB with 'read_hms'.
% 
%  See also: lm_features, lm_codes, read_hms.
%
