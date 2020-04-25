%  Columns of landmark labels (Nx2 char's.) for a column of landmark indices, OR vice versa.
% 	The abrupt landmarks are assigned as in 'landmarks'.  The type values have been as 
% 	follows (but could change, consistent with changes in 'landmarks'):
% 		+-g	~ 1, 2 (+-voicing)
% 		+-b ~ 3, 4 (+-burst)
% 		+-s ~ 5, 6 (+-sonorant-consonant release)
% 		+-f	~ 7, 8 (+-unvoiced fric.)
% 		+-v	~ 9, 10 (+- voiced fric.)
% 		+-p ~ 11, 12 (+- periodic voicing)
% 		...	(other landmark types)
%        +-T	~ 98, 99 (+- segment start/stop)
% 		??	~ other code.
% 
%  Notes: 
%  1.The indices are as from 'landmarks'; they correspond to features as in 'lm_features'.  
% 	Thus, the typical use of this function is in the form:
% 		... vector (list) L is assigned landmark code values by 'landmarks';
% 		labels = lm_labels(L(:)) .
%  2.If the argument is not a column vector, it will be converted to a column vector,
% 	with a warning message given.  The result will be returned as a column of strings 
% 	(i.e., a Nx2 character matrix) in all cases.
%  3.The "s" codes designate "syllabic", the RELEASE of a sonorant consonant (or "-s"
% 	for the opposite).
%  4.Abrupt landmarks (LMs) have 2-character lower-case labels for onset (+) and offset (-) 
% 	events.  Peak-type LMs have 1-letter, upper-case labels, preceded by a space
% 	character: for instance, " V" for a vowel.  ("V " would be unrecognized.)
% 
%  Examples:
%  1.CA = lm_labels([2 1 NaN 4 Inf]') produces the character array:
% 		CA = [+g; -g; ??; +b; ??] .
%  2.lm_labels(CA) produces the numeric array:
% 		[2; 1; NaN; 4; NaN] .
% 	Observe that this differs from the first input in that Inf has been converted to NaN.
% 
%  See also: landmarks, lm_features, warnmsg.
%
