function nsyls = lm_syl_count(LMS,FIELDNM)
% Total number of syllables as identifiably tied to speech production in a given LM array.
% Syntax:	nsyls = lm_syl_count(LMARR|{LMARR_K})
%			nsyls = lm_syl_count(LM_FNAME|{LM_FNAME_K})
%			nsyls = lm_syl_count(SYLSTRUCT_K,<FIELDNM>)
% where:
%	LMARR	= raw numeric landmark array ~ [times;types] with SIZE(LMARR,2) >= 2,
%			or a cell array of same;
%	LM_FNAME = ".lm" filename from which to read the LM array (with 'read_lms'); specify any
%			other extension (such as ".wav" or ".mat") to use EITHER a ".lm" or a ".mat" file, 
%			according to 'mat_conslms'; or cell array of such names;
%	SYLSTRUCT = syllable-synopsis structure, as from 'v_reportSylUtt', or an array of
%			such structures;
%	<FIELDNM> = name of SYLSTRUCT field [dflt. = "Count"] from which to extract syllable counts;
%	nsyls	= the total number of LM-identified syllables, or (if SYLSTRUCT is an array or 
%			if LMARR or LM_FNAME is a cell array) a corresponding array of the same size.
%
% Notes:
% 1.It is often helpful to synopsize the landmark structure first, in order to take advantage 
%	of "handmark" information (in a ".hm" file).  Otherwise, the landmarks are grouped into
%	syllables as from 'syl_lms'.
% 2.If LMARR, LM_FNAME, or SYLSTRUCT is an array, 'nsyls' will have the same size & shape (even if
%	not a vector).
% 3.Normally, FIELDNM = "Count", "CountB", or "CountAn" where "n" = 1 or 2.
% 4.The function 'lm_sylfilter' will filter all LMs in quiet syllables, while preserving LM
%	structure.  This can be helpful in preprocessing LMARR; however, it requires that the signal 
%	or its envelope be available.
%
% See also: v_reportSylUtt, syl_lms, mat_conslms, read_lms, lm_sylfilter.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2008-2010, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	08/12/26	NaN+... <- REPMAT(NaN,...) throughout.
%	SG	10/07/22	Added Note 4 to help documentation (ONLY).

STD_FIELDNM = 'Count';

if nargin == 1 && isequal(LMS,'?'),
    fprintf('%s\n', 'nsyls = lm_syl_count(LMARR|LM_FNAME)')
    fprintf('%s\n', 'nsyls_K = lm_syl_count({LMARR|LM_FNAME}_K)')
    fprintf('nsyls_K = lm_syl_count(SYLSTRUCT_K,<"%s"|FIELDNM>)\n',STD_FIELDNM)
    return
end

if nargin < 2, FIELDNM = ''; end	% Even for cell array (though we don't care in that case).
if isempty(FIELDNM), FIELDNM = STD_FIELDNM; end
	% >> All arg's. defined. <<
	
% Recurse over structure:
if (isstruct(LMS) && length(LMS) ~= 1) || iscell(LMS)	% No need for recursion if single struct/file.
	nsyls = repmat(NaN,[1,numel(LMS)]);	% 08/12/26: Was: NaN + zeros(1,numel(LMS));
	for kk = 1:numel(LMS)
		if iscell(LMS), nsyls(kk) = lm_syl_count(LMS{kk});	% FIELDNM irrelevant for cell array.
		else, nsyls(kk) = lm_syl_count(LMS(kk),FIELDNM);
		end
	end
	nsyls = reshape(nsyls,size(LMS));
		% >> SIZE(nsyls) = SIZE(<input arg. #1>). <<
	return
end

if isstruct(LMS),
	nsyls = numel(LMS.(FIELDNM));	% [Row]
elseif ischar(LMS)	% File-name case: read & recurse.
	if strcmpi('.lm',file_type(LMS)), lmarr = read_lms(LMS);
	else, lmarr = mat_conslms(LMS,NaN,NaN,'','load');
	end
	nsyls = lm_syl_count(lmarr);
else
	syl_lms(LMS);	% Starting LMs of each syl.
		nsyls = size(ans,2);
end
	% >> (Both paths:) 'nsyls' defined, scalar. <<
return
