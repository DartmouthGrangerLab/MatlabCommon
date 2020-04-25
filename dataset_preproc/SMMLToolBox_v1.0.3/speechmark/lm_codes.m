%  Landmark codes corresponding to specified list of landmark names.
% 	The purpose is to use a single set of "standard" names, regardless of internal names
% 	for the landmark types.
% 	The names (case-insensitive) are as follows:
% 		For abrupt-type landmarks:
% 		"PLUS_G", "MINUS_G": +-voicing, respectively
% 		"PLUS_B", "MINUS_B": +-burst
% 		"PLUS_S", "MINUS_S": +-syllabic (i.e., -+sonorant cons. release)
% 		"PLUS_F", "MINUS_F": +-unvoiced fricative
% 		"PLUS_V", "MINUS_V": +-voiced fricative
% 		"PLUS_P", "MINUS_P": +-periodicity (of voicing)
% 		"PLUS_J", "MINUS_J": abrupt increases and decreases of pitch (F0) in periodicity.
% 		For peak-type landmarks:
% 		"VOWEL"		: location of vowel center
% 		"FRICATION"	: location of center of frication or aspiration
% 		For meta-landmarks:
% 		"START_SEG:, "END_SEG": onset, offset of segment processing.
%    A name (string) should not appear more than once in the input arguments.
%    There must be one output argument for each input argument: NARGOUT == NARGIN.
% 	NaN	is returned as the code for any unsupported name.
% 
%  Examples:
%  1.  [VOICING_ONSET,BURST_OFF] = lm_codes('PLUS_G','MINUS_B')
% 	Notice that the internal names of the variables (VOICING_ONSET, BURST_OFF) do not need
% 	to be the same as the labels (strings) "PLUS_G", "MINUS_B".
%  2.  A fairly extensive set, assigning the numeric codes to variables having the 
% 	conventional names:
% 	[MINUS_G PLUS_G MINUS_B PLUS_B MINUS_S PLUS_S MINUS_F PLUS_F MINUS_V PLUS_V] = ...
%         lm_codes('MINUS_G','PLUS_G','MINUS_B','PLUS_B','MINUS_S', ...
% 					'PLUS_S','MINUS_F','PLUS_F','MINUS_V','PLUS_V');
% 
%  See also: lm_features, lm_labels.
%
