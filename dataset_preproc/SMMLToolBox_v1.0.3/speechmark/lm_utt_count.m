function nutts = lm_utt_count(LMS,FIELDNM_UTTGAP)
% Total number of utterances that are tied to speech production in a given LM array.
% Syntax:	nutts = lm_utt_count(LMARR|{LMARR_K},<UTT_GAP|NaN>)
%			nutts = lm_utt_count(LM_FNAME|{LM_FNAME_K},<UTT_GAP|NaN>)
%			nutts = lm_utt_count(UTTSTRUCT_K,<FIELDNM>)
% where:
%	LMARR	= raw numeric landmark array ~ [times;types] with SIZE(LMARR,2) >= 2,
%			or a cell array of same;
%	LM_FNAME = ".lm" filename from which to read the LM array (with 'read_lms'); specify any
%			other extension (such as ".wav" or ".mat") to use EITHER a ".lm" or a ".mat" file, 
%			according to 'mat_conslms'; or cell array of such names;
%	UTTSTRUCT = utterance-synopsis structure, as from 'v_reportSylUtt', or an array of
%			such structures;
%	<FIELDNM> = name of UTTSTRUCT field [dflt. = "Count"] from which to extract histogram
%			of syllable counts by syl. type;
%	<UTT_GAP> = minimum inter-utterance gap used to separate utterances, if not the default
%			of 'utt_starts'; specify NaN to force the use of 'utt_gap_std';
%	nutts	= the total number of LM-identified utterances that were found to be part of 
%			speech (syllables), or (if UTTSTRUCT is an array or if LMARR or LM_FNAME is 
%			a cell array) a corresponding array of the same size.
%
% Notes:
% 1.It is often helpful to synopsize the landmark structure first, in order to take advantage 
%	of "handmark" information (in a ".hm" file).  Otherwise, the landmarks are grouped into
%	utterances as from 'utt_starts'.
% 2.If LMARR, LM_FNAME, or UTTSTRUCT is an array, 'nutts' will have the same size & shape (even if
%	not a vector).
% 3.Normally, FIELDNM = "Count", "CountB", or "CountAn" where "n" = 1 or 2.
% 4.The function 'lm_sylfilter' will filter all LMs in quiet syllables, while preserving LM
%	structure.  This can be helpful in preprocessing LMARR; however, it requires that the signal 
%	or its envelope be available.
% 5.UTT_GAP is not available, nor is it needed, when processing an UTTSTRUCT structure.  Thus, the
%	interpretation of the 2nd input argument is unambiguous.
%
% See also: v_reportSylUtt, utt_starts, mat_conslms, read_lms, lm_sylfilter, utt_gap_std.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2008-2010, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	08/12/26 NaN+... <- REPMAT(NaN,...) throughout.
%   SG  10/07/22 Added Note 4 to help documentation (ONLY).
%	JM	10/11/9	Allow UTT_GAP arg.
%   RP  14/9/22 Apply function name chnages from std_* to *_std. Also, reflact changes in doc.

STD_FIELDNM = 'Count';

if nargin == 1 && isequal(LMS,'?'),
    fprintf('%s\n', 'nutts = lm_utt_count(LMARR|LM_FNAME),<UTT_GAP|NaN>')
    fprintf('%s\n', 'nutts_K = lm_utt_count({LMARR|LM_FNAME}_K),<UTT_GAP|NaN>')
    fprintf('nutts_K = lm_utt_count(UTTSTRUCT_K,<"%s"|FIELDNM>)\n',STD_FIELDNM)
    return
end

% ++ This should be rewritten to immediately invoke EITHER a structure-based OR a non-structure-based version.

% 10/11/9: Was: 
%	if nargin < 2, FIELDNM = ''; end	% Even for cell array (though we don't care in that case).
%	if isempty(FIELDNM), FIELDNM = STD_FIELDNM; end
if nargin < 2, FIELDNM_UTTGAP = []; end
if isstruct(LMS), FIELDNM = FIELDNM_UTTGAP; if isempty(FIELDNM), FIELDNM = STD_FIELDNM; end
else, UTTGAP = FIELDNM_UTTGAP; if isnan(UTTGAP), UTTGAP = utt_gap_std(); end % 14/9/22 Apply name chnage.
end
	% >> All arg's. defined if they will be needed. <<
	
% Recurse over structure:
if (isstruct(LMS) && length(LMS) ~= 1) || iscell(LMS)	% No need for recursion if single struct/file.
	nutts = repmat(NaN,[1,numel(LMS)]);	% 08/12/26: Was: NaN + zeros(1,numel(LMS));
	for kk = 1:numel(LMS)
		if iscell(LMS), nutts(kk) = lm_utt_count(LMS{kk},UTTGAP);	% FIELDNM irrelevant for cell array. 10/11/9: Added: ...,UTTGAP);
		else, nutts(kk) = lm_utt_count(LMS(kk),FIELDNM);
		end
	end
	nutts = reshape(nutts,size(LMS));
		% >> SIZE(nutts) = SIZE(<input arg. #1>). <<
	return
end

if isstruct(LMS),
	nutts = numel(LMS.(FIELDNM));	% [Row]
elseif ischar(LMS)	% File-name case: recurse.
	if strcmpi('.lm',file_type(LMS)), lmarr = read_lms(LMS);
	else, lmarr = mat_conslms(LMS,NaN,NaN,'','load');
	end
	nutts = lm_utt_count(lmarr,UTTGAP);	% 10/11/9: Added: ...,UTTGAP);
else
	% 10/11/9: Was: utt_starts(LMS);	% Starting LMs of each utt.
	utt_starts(LMS,[],[],[],[],UTTGAP);	% Starting LMs of each utt.	
		nutts = size(ans,2);
end
	% >> (Both paths:) 'nutts' defined, scalar. <<
return
