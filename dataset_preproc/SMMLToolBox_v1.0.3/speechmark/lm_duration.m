function dur = lm_duration(LMS)
% Total duration [sec] of speech based on landmarks that are tied to speech production.
% 
% Syntax:	dur	= lm_duration(LMARR|{LMARR_K})
%			dur	= lm_duration(LM_STRUCT|LM_STRUCT_K)
%			dur	= lm_duration(LM_FNAME|{LM_FNAME_K})
%
%   where:
%	LMARR	= raw numeric landmark array ~ [times;types] with SIZE(LMARR,2) >= 2, or a 
%			cell array of same;
%	LMSTRUCT = raw landmark structure ~ [.time;.type], or a cell array of same;
%	LM_FNAME = ".lm" filename from which to read the LM array (with 'read_lms'); specify any
%			other extension (such as ".wav" or ".mat") to use EITHER a ".lm" or a ".mat" file, 
%			according to 'mat_conslms'; or cell array of such names;
%	dur		= the total duration of produced speech from start of first utterance to end of last,
%			or NaN if this cannot be determined;
%			or (if UTTSTRUCT is an array or if LMARR or LM_FNAME is a cell array) a 
%			corresponding array of the same size.
%
% Notes:
% 1.It is often helpful to synopsize the landmark structure first, in order to take advantage 
%	of "handmark" information (in a ".hm" file), as by 'lm_hmfilt'.  Otherwise, the landmarks
%	are grouped into utterances as from 'utt_lms'.
% 2.If LMARR or LM_FNAME is an array, 'dur' will have the same size & shape (even if not 
%	a vector).
% 3.The function 'lm_sylfilter' will filter all LMs in quiet syllables, while preserving LM
%	structure.  This can be helpful in preprocessing LMARR; however, it requires that the signal 
%	or its envelope be available.
% 4.If the first LM is inappropriate for the start of an utterance (e.g., a "+s"), then the
%	first utterance will be taken to start at time = 0.
%
% See also: utt_lms, mat_conslms, read_lms, lm_sylfilter, lm_hmfilt.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2010, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	11/1/22	Small fix to "?" msg. (ONLY).
%   CA 12/10/19 Documentation.

if nargin == 1 && isequal(LMS,'?'),
    fprintf('%s\n', 'dur_sec = lm_duration(LMARR|LMSTRUCT|LM_FNAME)')
    fprintf('%s\n', 'dur_sec_K = lm_duration({LMARR|LM_FNAME}_K|LMSTRUCT_K)')	% 11/1/22: 'lm_count' <- 'lm_duration'.
    return
end

% Recurse over structure:
if (isstruct(LMS) && length(LMS) ~= 1) || iscell(LMS)	% No need for recursion if single struct/file.
	% >> LMS is NOT a numeric LM array. <<
	dur = repmat(NaN,[1,numel(LMS)]);
	for kk = 1:numel(LMS)
		if iscell(LMS), dur(kk) = lm_duration(LMS{kk});	% [Sec] Whether LM array or filename array.
		else, dur(kk) = lm_duration(LMS(kk));	% [Sec] Must be a structure array.
		end
	end
	dur = reshape(dur,size(LMS));	% [Sec] Remember that LMS is NOT a numeric LM array.
	% >> (All paths:) SIZE(dur) = SIZE(LMS); 'dur(*)' defined, scalar, [Seconds], NaN or >= 0. <<
	return
end

% Single file/array cases:
if isstruct(LMS)	% Single LM structure.  
	% Since 'utt_lms' does not (now?) support structures, convert to numeric & recurse:
	dur = lm_duration(lm_structarr(LMS));	% [Sec]
	% >> 'dur' defined, scalar, [Seconds], NaN or >= 0. <<
elseif ischar(LMS)	% Single file-name case: recurse.
	if strcmpi('.lm',file_type(LMS)), lmarr = read_lms(LMS);
	else, lmarr = mat_conslms(LMS,NaN,NaN,'','load');
	end
	dur = lm_duration(lmarr);	% [Sec]
	% >> (Both paths:) 'dur' defined, scalar, [Seconds], NaN or >= 0. <<
else	% Numeric LM array:
	onoffs = utt_lms(LMS);	% 2xN: Indices (into LMS) of [start; end] of utterances.
	if isempty(onoffs), dur = 0;	% [Sec]
	else
		if onoffs(1) < 1, 0; else, LMS(1,onoffs(1)); end	% [Sec] 0, or starting time of first utt.
		dur = LMS(1,min(end,onoffs(end))) - ans;	% [Sec] Ending time of last utt. - start.
	end
	% >> (Both paths:) 'dur' defined, scalar, [Seconds], NaN or >= 0. <<
end
	% >> (All paths:) 'dur' defined, scalar, [Seconds], NaN or >= 0. <<
return
