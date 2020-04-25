function [maxf0,minf0] = maxf0_std(AGE_GENDER)
% Max., and optionally min., F0's for typical normal humans of given ages and/or genders (or "N").
% Syntax:	[maxf0s,<minf0s>] = maxf0_std(<AGE_GENDERS>)
% where:
%	<AGE_GENDERS> = letters (case-insens.) for:
%			speaker gender for adults: "N", "F" or "M";
%			or age: "I", "C", or "E" for infants, children, or elderly, resp.;
%			dflt. = '' (equiv. to "N"), which produces the highest 'maxf0' value that is 
%				typical of adults, i.e., that for females, and the lowest 'minf0', i.e.,
%				that for elderly;
%			specify one letter for each value desired;
%	maxf0s	= max. fund. freq. to be expected for normal human speech, arranged in a
%			column, for each element of AGE_GENDERS (regardless of the SHAPE of AGE_GENDERS);
%	<minf0s> = min. fund. freq's., similarly; see Notes.
%
% Notes:
% 1.Max. F0 is used by many pitch-sensitive functions, including 'lmadult' and 'nonbreathy'.
% 2.The order for 'maxf0' is "m" < "e" <= "f" <= "c" < "i".  The order for 'minf0' is
%	"e" <= "m" < "f" <= "c" <= "i".
% 3.Generally, 'minf0' ~ 'maxf0'/4.  However, infants especially may have a wider range,
%	and elderly adults may have lower minimum values than this.
% 4.The "k"-th row of 'maxf0' and 'minf0' corresponds to AGE_GENDER("k").
%
% Examples:
%	x = maxf0_std('mf')	yields x = [220; 350].  So does x = maxf0_std(['m';'f']).
%
% See also: lmadult, nonbreathy.

%	Trade secret of Speech Technology & Applied Research Corp.
%	Copyright 2005-2008, Speech Technology & Applied Research Corp, (unpublished)
%
%	JM	06/2/13	Created, based on pst_maxf0.
%	JM	06/3/11	STDXE changed from = STDXM; dflt. ("N") 'minf0' = male (was elderly).
%	JM	08/1/31	Allow multiple AGE_GENDER codes.
%		08/9/30	Small change STDNI code, STDNE value (never previously used by 
%				any application).
%   RP  14/9/19 Name change std_maxf0 -> maxf0_std.

% Max's:
STDXM = 220; STDXF = 350; STDXC = 500; STDXI = 1200;
STDXE = (STDXM+STDXF)/2;
% Min's:
STDNM = STDXM/4; STDNF = STDXF/4; STDNC = STDXC/5; 
% 08/9/30: Was: STDNI = STDXI/8; STDNE = STDXE/4;
STDNI = max(STDNC,STDXI/8); STDNE = min(STDNM,STDXE/4);

if nargin==1 && isequal(AGE_GENDER,'?'),
    fprintf('%s\n', '[maxf0,<minf0>] = maxf0_std(<"n"|AGE_GENDER|"m"|"f"|"i"|"c"|"e">)')
    return
end

if nargin < 1, AGE_GENDER = ''; end
if isempty(AGE_GENDER), AGE_GENDER = 'N'; end	% Dflt. = "N": adult, no gender-specific info.

% 08/1/31: Recurse to handle multiple codes:
if length(AGE_GENDER) <= 1,
	switch(upper(AGE_GENDER))
		case 'M', maxf0 = STDXM;
		case {'F','N'}, maxf0 = STDXF;	% "N" => no info => use higher for max.
		case 'C', maxf0 = STDXC;
		case 'I', maxf0 = STDXI;
		case 'E', maxf0 = STDXE;
		otherwise, maxf0 = NaN;
	end

	switch(upper(AGE_GENDER))
		case {'M','N'}, minf0 = STDNM;	% "N" => no info => use lowest for min.
		case 'F', minf0 = STDNF;
		case 'C', minf0 = STDNC;
		case 'I', minf0 = STDNI;
		case 'E', minf0 = STDNE;
		otherwise, minf0 = NaN;
	end
else	% Tail recursion:
	[maxf01,minf01] = maxf0_std(AGE_GENDER(1));
	[maxf0,minf0] = maxf0_std(AGE_GENDER(2:end));
	maxf0 = [maxf01; maxf0];	% [Col.]
	minf0 = [minf01; minf0];	% [Col.]
end
