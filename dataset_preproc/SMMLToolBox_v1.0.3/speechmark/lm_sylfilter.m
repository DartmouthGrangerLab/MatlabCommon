%  Filters out all LMs that are in quiet syl. clusters that contain +g AND -g, or not in clusters.
%  Syntax: [lmsf, kept_syl_ind] = lm_sylfilter(LMS, <DEGSPE>, <RATE>, <THRESH>)
%    LMS         = Numeric or structure array of landmarks;
%    DEGSPE      = Degree [dflt. = 1] to which speech is taken to be present (esp. based on its
% 				envelope, as with 'deg_speechenv'); see Notes;
% 	RATE		= sampling rate [Hz; dflt. = 16000] of DEGSPE;
% 	THRESH		= min. degree [in 0-1, dflt. = 1/2] of mean DEGSPE value for retention of LMs 
% 				of each syl.;
%    lmsf        = Filtered LM array, with the same components as LMS, but (possibly) fewer 
% 				entries;
%    kept_syl_ind = Indices of the original LMS syllables that were retained in 'lmsf'.
% 
%  Notes:
%  1.The restriction to syllables containing both +g and -g avoids the ambiguous problem of:
% 		+g -s | +s -g (where "|" denotes a syl. boundary);
% 	if either syl. were suppressed, but the other was not, then the resulting LM sequence
% 	would have an unpaired "g", an invalid condition.  The effect of this function is to
% 	keep all syllables within a single voiced region if ANY of them is to be kept (has a high
% 	mean value of DEGSPE).
%  2.If DEGSPE is a scalar, this will be interpreted as a constant array of that value, with
% 	length >= RATE*(last LM's time).  Note that even with entirely default values, LMs may
% 	be removed if they lie sufficiently far from any voiced region.
%  3.It is generally better to use 'deg_speechenv' or 'deg_speechenv_local' for DEGSPE, rather 
% 	than 'deg_speech' with LMs, because the LMs will cause the "detection" of speech even in
% 	the regions that this function is designed to suppress, thus defeating the filtering.
% 	See the Example.
%  4.A value such as 
% 		'entropy_thr(DEGSPE)',
% 		'fractile(DEGSPE,0.1)',
% 	or even
% 		'justmore(0)'
% 	may be a more appropriate threshold than 1/2 for some applications.
% 
%  Example: For LMS = [0.5 1 1.0160; 3  2  1; 1  1  -1], 'lm_sylfilter' yields
% 	[ 1 1.0160; 2 1; 1 -1], the 2nd and 3rd LMs.  Notice that the last 3 arguments are 
% 	omitted (defaulted).
% 
%  See also: clarity_capture_score, deg_speech*, syl_lms, entropy_thr, fractile.
%
