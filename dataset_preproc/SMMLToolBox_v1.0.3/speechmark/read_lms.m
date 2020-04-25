%  Read specified file of landmark times/labels, as from 'write_lms': one per line.
%    lms2xN = read_lms(FNAME)
% 	lms3xN = read_lms(FNAME)
% 
%  Notes: 
%  1.Times must be in SECONDS, labels must be the standard 2-char labels ~ 'lm_labels'.
%  2.If a 3rd field exists (landmark "strength"), it must be a floating-point value between -1.0
% 	and +1.0, and it must be present on every line.  It will be returned in the 3rd row of the
% 	output.
% 
%  See also: lm_labels, write_lms.
%
