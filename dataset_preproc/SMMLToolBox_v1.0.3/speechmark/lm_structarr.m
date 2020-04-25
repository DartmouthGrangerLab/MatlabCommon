function lmsout = lm_structarr(LMSIN)
% Landmark structure array corresp. to a given LM numeric array, or vice versa.
% Syntax:
%	lms_arr = lm_structarr(LMSSTRUCT)
%	lms_struct = lm_structarr(LMSARR)
% where:
%	lms_arr		= numeric LM array corresp. to the structure array LMSSTRUCT;
%	lms_struct	= LM structure array corresp. to the numeric LM array LMSARR.
%	
% Notes:
%	The fields defined in 'lms_struct' depend on the existence of certain rows in 
%	LMSARR, and the existence of certain rows in 'lms_arr' depends on the fields defined
%	in LMSSTUCT.
%
% See also: lm_labels, abrupt_lms.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2007-2013, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	08/5/12	Fix defect in 'lm_arr2struct': Allow LMSARR = empty, yet preserve SIZE(LMSARR).
%	JM	13/11/24 Small change to doc. (ONLY).

if nargin == 1 && isequal(LMSIN,'?'),
    fprintf('%s\n','lms_arr_KxN = lm_structarr(LMSSTRUCT_N)')
    fprintf('%s\n','lms_struct_N = lm_structarr(LMSARR_KxN)')
	return
end

if isstruct(LMSIN), lmsout = lm_struct2arr(LMSIN);
else, lmsout = lm_arr2struct(LMSIN);
end
return

% --------------------------

function lms_arr = lm_struct2arr(LMSSTRUCT)
% Convert N-element structure array (of ANY shape) to numeric KxN array.
lms_arr = [LMSSTRUCT(:).time; LMSSTRUCT(:).type];
strmatch('strength',fieldnames(LMSSTRUCT),'exact');
	if ~isempty(ans), lms_arr(3,:) = [LMSSTRUCT(:).strength]; end
return

% --------------------------

function lms_struct = lm_arr2struct(LMSARR)
% Convert KxN-element numeric LM array to 1xN structure array, of suitable fieldnames.
%
%	08/5/12	Fix defect: Allow LMSARR = empty, yet preserve SIZE(LMSARR).
if size(LMSARR,1) > 3, warnmsg('Conversion of LM arrays does not support rows > 3.'), end
% 08/5/12: Was: num2cell(LMSARR);
%	lms_struct = cell2struct(ans,index({'time','type','strength'},1:min(3,size(LMSARR,1))),1)';
fields = index({'time','type','strength'},1:min(3,size(LMSARR,1)));
% Transpose just so SIZE(lms_struct,2) = SIZE(LMSARR,2):
if isempty(LMSARR), lms_struct = cell2struct(cell(size(LMSARR)),fields,1)';
else, lms_struct = cell2struct(num2cell(LMSARR),fields,1)';
end
return
