function tf = lm_isvoiced(LMCODES)
% Specify voicing state a landmark type(s).
% Syntax:	tf = lm_isvoiced(LMCODES)
%
% where:
%	LMCODES	= landmark numeric type-code, or an array of same;
%	tf		= vocing state (TRUE/FALSE) for each element of LMS.
%
% Example:
%	lms = lmadult(...);	% Array of [LM times; LM type-code; ...].
%	voicingstate = lm_isvoiced(lms(2,:));	% Voicing state of each LM in 'lms'.
%
% See also: lm_features, lm2voicing.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2008-2009, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	09/5/18	Small change to doc. (ONLY).

if nargin==1 && isequal(LMCODES,'?'),
    fprintf('%s\n', 'tf = lm_isvoiced(LMCODES)')
	return
end

persistent VOICEDCODES
if isempty(VOICEDCODES), VOICEDCODES = lm_features('VOICED'); end

tf = ismember(LMCODES,VOICEDCODES);
