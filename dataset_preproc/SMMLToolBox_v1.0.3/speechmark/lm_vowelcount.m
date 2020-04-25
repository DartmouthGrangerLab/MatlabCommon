function nvlms = lm_vowelcount(VLMARR_FNAME)
% Number of all vowel landmarks in all syllables in given vowel-LM array or a given ".wav" or ".mat" file.
% Syntax:	nvlms	= lm_vowelcount(VLMARR|WAV_FNAME|MAT_FNAME)
%			nvlms_N	= lm_vowelcount({VLMARR|WAV_FNAME|MAT_FNAME}_N)
% where:
%	VLMARR	= vowel-landmark array as from 'vowel_lms', or cell array of same;
%	WAV_FNAME|MAT_FNAME = ".mat" or ".wav" filename from which to read or compute the 
%			vowel-LM array (with 'mat_vowel_segs'); or cell array of such names;
%	nvlms	= number of vowel-LMs in the vowel-LM array [see Notes]; if the input is
%			a cell array, then 'nvlms' will be a numeric array if the same size.
%
% Notes: 
% 1.If VLMARR, VLM_FNAME, or MAT_FNAME is an array, 'nvlms' will have the same size & 
%	shape (even if not a vector).
% 2.The number of vowel-LMs is not the same as the number of LM-identified syllables, nor of
%	vowel segments: There can be multiple vowel-LMs in a segment or a syllable (e.g., from 
%	diphthongs).  For the number of syllables, use 'lm_syl_count' instead.  This is normally
%	equal to the number of vowel segments.
% 3.If *_FNAME is a MAT file, 'mat_vowel_segs' will read with the KEEP argument = "load".  
%	Otherwise, it will read with KEEP = "same".
%
% See also: lm_syl_count, vowel_lms, mat_vowel_segs.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2008, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	08/5/11	Change to "?" processing (ONLY).
%		08/7/21	Fix defect for empty 'vlmarr'.
%		08/9/15	Change to doc. (ONLY).
%		08/12/26 NaN+... <- REPMAT(NaN,...) throughout.

if nargin==1 && isequal(VLMARR_FNAME,'?'),
    fprintf('%s\n', 'nvlms = lm_vowelcount(VLMARR|WAV_FNAME|MAT_FNAME)')
    fprintf('%s\n', 'nvlms_N = lm_vowelcount({VLMARR|WAV_FNAME|MAT_FNAME}_N)')
	return
end

if iscell(VLMARR_FNAME)	% Iterate (NOT recurse) over cell array of inputs?
	nvlms = repmat(NaN,size(VLMARR_FNAME));	% 08/12/26: Was: NaN + zeros(size(VLMARR_FNAME));
	for kk = 1:numel(VLMARR_FNAME)
		nvlms(kk) = lm_vowelcount(VLMARR_FNAME{kk});
	end
	return
end
	% >> VLMARR_FNAME is NOT a cell array. <<
	
if ischar(VLMARR_FNAME), 
	if strcmpi('.mat',file_type(VLMARR_FNAME)), 
		fid_merge('.wav',VLMARR_FNAME);	% 'mat_vowel_segs' requires ".wav", even to read a ".mat":
			[vsegs,vlmarr] = mat_vowel_segs(ans,[],[],[],'','load');	% MAT case.
	else, [vsegs,vlmarr] = mat_vowel_segs(VLMARR_FNAME,[],[],[],'','same');	% WAV (or other) case.
	end
else
	vlmarr = VLMARR_FNAME; 
end
	% >> 'vlmarr' = array of vowel LMs. <<

% "Real" (adequately long, voiced) vowels:
% 08/7/21: Fix defect: Was: vlmarr(3,:) > 0; nvlms = numel(vlmarr(ans));	% Even if this is NUMEL([]).
if size(vlmarr,2) == 0, nvlms = 0; else, nvlms = sum(vlmarr(3,:)>0); end
