%  Total number of landmarks that are tied to speech production in a given LM array.
%  Syntax:	nlms = lm_count(LMARR|{LMARR_K})
% 			nlms = lm_count(LM_FNAME|{LM_FNAME_K})
% 			nlms = lm_count(SYLSTRUCT_K,<FIELDNM>)
%  where:
% 	LMARR	= raw numeric landmark array ~ [times;types] with SIZE(LMARR,2) >= 2,
% 			or a cell array of same;
% 	LM_FNAME = ".lm" filename from which to read the LM array (with 'read_lms'); specify any
% 			other extension (such as ".wav" or ".mat") to use EITHER a ".lm" or a ".mat" file, 
% 			according to 'mat_conslms'; or cell array of such names;
% 	SYLSTRUCT = syllable-synopsis structure, as from 'v_reportSylUtt', or an array of
% 			such structures;
% 	<FIELDNM> = name of SYLSTRUCT field [dflt. = "Count"] from which to extract histogram
% 			of syllable counts by syl. type;
% 	nlms	= the total number of LMs that were found to be part of speech (syllables),
% 			or (if SYLSTRUCT is an array or if LMARR or LM_FNAME is a cell array) a 
% 			corresponding array of the same size.
% 
%  Notes:
%  1.It is often helpful to synopsize the landmark structure first, in order to take advantage 
% 	of "handmark" information (in a ".hm" file).  Otherwise, the landmarks are grouped into
% 	syllables as from 'syl_lms'.
%  2.If LMARR, LM_FNAME, or SYLSTRUCT is an array, 'nlms' will have the same size & shape (even if
% 	not a vector).
%  3.Normally, FIELDNM = "Count", "CountB", or "CountAn" where "n" = 1 or 2.
%  4.The function 'lm_sylfilter' will filter all LMs in quiet syllables, while preserving LM
% 	structure.  This can be helpful in preprocessing LMARR; however, it requires that the signal 
% 	or its envelope be available.
% 
%  See also: v_reportSylUtt, syl_lms, mat_conslms, read_lms, lm_sylfilter.
%
