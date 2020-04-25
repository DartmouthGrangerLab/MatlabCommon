function hplim = lm_hplim_std(AGE)
% Standard freq. limit for high-pass filter before landmark speech-signal processing.
%	Syntax:	hplim = lm_hplim_std(AGE)
%   <AGE>	= "ADULT" [default] or "CHILD" for the freq. limit for this age group;
%	hplim	= cutoff frequency [Hz] of the high-pass filter.
%
% See also: lmadult.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2008, Speech Technology & Applied Research Corp, (unpublished)
%
%   RP 14/09/19 Name change std_lm_hplim -> lm_hplim_std.

if nargin==1 && isequal(AGE,'?'),	% 07/8/27: Block added.
    fprintf('%s\n','hplim = lm_hplim_std(<"adult"|AGE|"child">)')
    return
end

if nargin < 1, AGE = ''; end
if isempty(AGE), AGE = 'ADULT'; end

if strcmpi(AGE,'ADULT')	% for adults:
    hplim = 75;	% [Hz]
else %AGE == 'CHILD'	% adjusted for infants:
    hplim = 150;	% [Hz]
end;
