function dur = lm_totalvoiced(LMARR_FNAME)
% Sum of all voiced-interval durations in given LM array or a given ".lm" file.
% Syntax:	dur		= lm_totalvoiced(LMARR|LM_FNAME|MAT_FNAME)
%			dur_n	= lm_totalvoiced({LMARR|LM_FNAME|MAT_FNAME}_N)
% where:
%	LMARR	= landmark array, or cell array of same;
%	LM_FNAME = ".lm" filename from which to read the LM array (with 'read_lms'); specify 
%			any other extension (such as ".wav" or ".mat") to use EITHER a ".lm" or a 
%			".mat" file, according to 'mat_conslms'; or cell array of such names;
%	dur		= total of all voicing time (+g to -g); if the input is a cell array, then 
%			'dur' will be a numeric array if the same size.
%
% Note: If voicing starts before time = 0, the beginning of the array (i.e., if the
%	first -g poccurs before the first +g), it will be assumed to start at 0.  If it 
%	extends beyond the end (last +g occurs after last -g), it will be assumed to extend
%	to the last landmark.  This will generally occur before the end of the waveform itself.
%
% See also: mat_conslms, read_lms.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2008, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	08/12/26 NaN+... <- REPMAT(NaN,...) throughout.

if nargin==1 && isequal(LMARR_FNAME,'?'),
    fprintf('%s\n', 'dur = lm_totalvoiced(LMARR)')
    fprintf('%s\n', 'dur = lm_totalvoiced(LM_FNAME)')
    fprintf('%s\n', 'dur = lm_totalvoiced(MAT_FNAME)')
    fprintf('%s\n', 'dur_n = lm_totalvoiced({ARR_FNAME}_N)')
	return
end

persistent PLUS_G MINUS_G
if isempty(PLUS_G), [PLUS_G,MINUS_G] = lm_codes('PLUS_G','MINUS_G'); end

if iscell(LMARR_FNAME)	% Iterate (NOT recurse) over cell array of inputs?
	dur = repmat(NaN,size(LMARR_FNAME));	% 08/12/26: Was: NaN + zeros(size(LMARR_FNAME));
	for kk = 1:numel(LMARR_FNAME)
		dur(kk) = lm_totalvoiced(LMARR_FNAME{kk});
	end
	return
end
	% >> LMARR_FNAME is NOT a cell array. <<
	
if ischar(LMARR_FNAME), 
	if strcmpi('.lm',file_type(LMARR_FNAME)), lmarr = read_lms(LMARR_FNAME);
	else, lmarr = mat_conslms(LMARR_FNAME,NaN,NaN,'','load');
	end
else
	lmarr = LMARR_FNAME; 
end

if isempty(lmarr), dur = 0; return, end

ndxpg = find(lmarr(2,:)==PLUS_G);	% [Row]
	% Check for empty 'ndxpg', and missing +g at front:
	if lm_isvoiced(lmarr(2,1)) && ~isequal(ndxnull(ndxpg,1),1), ndxpg = [1, ndxpg]; end
ndxmg = find(lmarr(2,:)==MINUS_G);	% [Row]
	% Check for empty 'ndxmg', and missing -g at end:
	size(lmarr,2);
		if lm_isvoiced(lmarr(2,end)) && ~isequal(ndxnull(ndxmg,numel(ndxmg)),ans), 
			ndxmg = [ndxmg, ans]; 
		end

% >> (Error in 'lmarr', or:) NUMEL(ndxpg) = NUMEL(ndxmg). <<
lmarr(1,ndxmg) - lmarr(1,ndxpg);	% Time diff. between each +g & next -g.
	dur = sum(ans);

