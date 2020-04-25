function dur = lm_totalvot(LMARR_FNAME,MAXDUR)
% Sum of all voice-onset times in all syllables in given LM array or a given ".lm" file.
% Syntax:	dur		= lm_totalvot(LMARR|LM_FNAME|MAT_FNAME,<MAXDUR>)
%			dur_n	= lm_totalvot({LMARR|LM_FNAME|MAT_FNAME}_N,<MAXDUR>)
% where:
%	LMARR	= landmark array, or cell array of same;
%	LM_FNAME = ".lm" filename from which to read the LM array (with 'read_lms'); specify any
%			other extension (such as ".wav" or ".mat") to use EITHER a ".lm" or a ".mat" file, 
%			according to 'mat_conslms'; or cell array of such names;
%	<MAXDUR> = upper limit [secons; default = Inf] to individual VOTs; VOTs above this will
%			be clipped to MAXDUR before being included in the total;
%	dur		= total of VOTs for each identified syllable in the LM array; if the input is
%			a cell array, then 'dur' will be a numeric array of the same size.
%
% Note: This function simply returns the sum of all VOTs found by 'lm_sylvots' (which see),
%	apart from possible clipping by MAXDUR.
%
% See also: lm_sylvots, mat_conslms, read_lms.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2007-2010, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	07/12/20 Loop over cell-array of inputs -> numeric array of outputs.
%	JM	08/12/26 NaN+... <- REPMAT(NaN,...) throughout.
%	JM	10/7/28	Remove irrelevant (and sometimes slow) call to 'read_lms'/'mat_conslms'.
%		10/10/14 Support MAXDUR.

if nargin==1 && isequal(LMARR_FNAME,'?')	% 10/10/14: ",<+Inf|MAXDUR_sec>" added to each msg.:
    fprintf('%s\n', 'dur = lm_totalvot(LMARR,<+Inf|MAXDUR_sec>)')
    fprintf('%s\n', 'dur = lm_totalvot(LM_FNAME,<+Inf|MAXDUR_sec>)')
    fprintf('%s\n', 'dur = lm_totalvot(MAT_FNAME,<+Inf|MAXDUR_sec>)')
    fprintf('%s\n', 'dur_n = lm_totalvot({ARR_FNAME}_N,<+Inf|MAXDUR_sec>)')	% 07/12/20: Added.
	return
end

if nargin < 2 || isempty(MAXDUR), MAXDUR = +Inf; end	% 10/10/14: Added.

% 07/12/20: Block added:
if iscell(LMARR_FNAME)	% Iterate (NOT tail-recurse) over cell array of inputs, recursing for each file/array.
	dur = repmat(NaN,size(LMARR_FNAME));	% 08/12/26: Was: NaN + zeros(size(LMARR_FNAME));
	for kk = 1:numel(LMARR_FNAME)
		dur(kk) = lm_totalvot(LMARR_FNAME{kk},MAXDUR);	% 1010/14: MAXDUR arg. added.
	end
	return
end
	% >> LMARR_FNAME is NOT a cell array. <<
	
% 10/7/28: Remove block per MLINT: 'lmarr' is unused (and 'mat_conslms' takes most of the time):
% if ischar(LMARR_FNAME),
% 	if strcmpi('.lm',file_type(LMARR_FNAME)), lmarr = read_lms(LMARR_FNAME);
% 	else, lmarr = mat_conslms(LMARR_FNAME,NaN,NaN,'','load');
% 	end
% else
% 	lmarr = LMARR_FNAME;
% end

% 10/10/14: Added MAXDUR.  Was: dur = sum(lm_sylvots(LMARR_FNAME));
dur = sum(min(MAXDUR,lm_sylvots(LMARR_FNAME)));	% Even if this is SUM([]) (which = 0, as we want).
