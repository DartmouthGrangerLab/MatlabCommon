function [durs,ndxsyls] = lm_sylvots(LMARR_FNAME)
% Array of voice-onset times for each syllable in given LM array or a given ".lm/.mat/.wav" file.
% Syntax: [durs,ndxsyls] = lm_sylvots(LMARR|LM_FNAME|MAT_FNAME)
% where:
%	LMARR	= landmark array;
%	LM_FNAME = ".lm" filename from which to read the LM array (with 'read_lms'); specify any
%			other extension (such as ".wav" or ".mat") to use EITHER a ".lm" or a ".mat" file, 
%			according to 'mat_conslms';
%	durs	= total of VOTs for each identified syllable in the LM array;
%	ndxsyls	= indices (into LMARR(1,:)) of syl. [starts; ends].
%
% Notes:
% 1.The syllables are identified by the rules in 'syl_lms'.
% 2.The VOT of a single syllable is defined here by the time from the first LM of the syl. 
%	to the start of voicing.  Syllables that contain no voicing onset (i.e., that simply
%	continue previous voicing) are assigned a VOT of 0.
% 3.Only the time and type rows of the array are used.
% 4.'mat_conslms' may still use a ".lm" file if present, even if a ".mat" file (of the same name)
%	exists.  No verification of the parameters (sampling rate, etc.) that were used to create
%	that file will be performed, and (if absent) a new LM or MAT file may or may not be created.
%
% See also: syl_lms, read_lms, mat_conslms.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2007-2010, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	08/9/9	Add 'ndxsyls' to output arg. list & corresp. "?".  (NO other changes to code.)
%	JM	10/7/28	"use0" replaces "load" arg. in call to 'mat_conslms'.

if nargin==1 && isequal(LMARR_FNAME,'?'),
    fprintf('%s\n', '[durs_K,ndxsyls_2xK] = lm_sylvots(LMARR)')
    fprintf('%s\n', '[durs_K,ndxsyls_2xK] = lm_sylvots(LM_FNAME)')
    fprintf('%s\n', '[durs_K,ndxsyls_2xK] = lm_sylvots(MAT_FNAME)')
	return
end

if ischar(LMARR_FNAME), 
	if strcmpi('.lm',file_type(LMARR_FNAME)), lmarr = read_lms(LMARR_FNAME);
	else, lmarr = mat_conslms(LMARR_FNAME,NaN,NaN,'','use0');	% 10/7/28: "use0" replaces "load".
	end
else
	lmarr = LMARR_FNAME; 
end

PLUS_G = lm_codes('PLUS_G');	% Whatever code is a "+g".
ndxsyls = max(1,min(size(lmarr,2),syl_lms(lmarr)));	% Clip any +-Inf values to ends of 'lmarr'.
	% >> Each col. = 1st & last LM indices into rows of 'lmarr'. <<
durs = zeros(1,size(ndxsyls,2));	% Zero unless we see a +g.
for syl = 1:size(durs,2)
	ndxs = ndxsyls(1,syl):ndxsyls(2,syl);	% The relevant indices for current syl.
	find(lmarr(2,ndxs)==PLUS_G);
		if ~isempty(ans)	% Ignore this syl. if no "+g" (keep time = 0).
			% Times for first voicing vs. 1st LM of the syl.:
			durs(syl) = lmarr(1,ndxs(ans)) - lmarr(1,ndxs(1));
		end
end
